
/****** Object:  UserDefinedTableType [dbo].[ImageType]    Script Date: 5/29/2017 11:10:04 AM ******/
CREATE TYPE [dbo].[ImageType] AS TABLE(
	[Id] [uniqueidentifier] NOT NULL,
	[ImageName] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[People] [nvarchar](max) NULL,
	[Tags] [nvarchar](max) NULL
)
GO
/****** Object:  Table [dbo].[Image]    Script Date: 5/29/2017 11:10:05 AM ******/

CREATE TABLE [dbo].[Image](
	[Id] [uniqueidentifier] NOT NULL,
	[ImageName] [nvarchar](150) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[DateCreated] [datetime] NULL,
 CONSTRAINT [PK__tmp_ms_x__3214EC07B5138A5B] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

GO
/****** Object:  Table [dbo].[ImagePerson]    Script Date: 5/29/2017 11:10:05 AM ******/

CREATE TABLE [dbo].[ImagePerson](
	[ImageId] [uniqueidentifier] NOT NULL,
	[PersonId] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](150) NOT NULL,
	[DateCreated] [datetime] NULL,
 CONSTRAINT [PK_ImagePerson] PRIMARY KEY CLUSTERED 
(
	[PersonId] ASC,
	[ImageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

GO
/****** Object:  Table [dbo].[ImageTag]    Script Date: 5/29/2017 11:10:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ImageTag](
	[ImageId] [uniqueidentifier] NOT NULL,
	[Tag] [nvarchar](50) NOT NULL,
	[DateCreated] [datetime] NULL,
 CONSTRAINT [PK_ImageTag] PRIMARY KEY CLUSTERED 
(
	[Tag] ASC,
	[ImageId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
)

GO
ALTER TABLE [dbo].[Image] ADD  CONSTRAINT [DF_Image_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [dbo].[ImagePerson] ADD  CONSTRAINT [DF_ImagePerson_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [dbo].[ImageTag] ADD  CONSTRAINT [DF_ImageTag_DateCreated]  DEFAULT (getdate()) FOR [DateCreated]
GO
ALTER TABLE [dbo].[ImagePerson]  WITH CHECK ADD  CONSTRAINT [FK_ImagePerson_ToImage] FOREIGN KEY([ImageId])
REFERENCES [dbo].[Image] ([Id])
GO
ALTER TABLE [dbo].[ImagePerson] CHECK CONSTRAINT [FK_ImagePerson_ToImage]
GO
ALTER TABLE [dbo].[ImageTag]  WITH CHECK ADD  CONSTRAINT [FK_ImageTag_ToImage] FOREIGN KEY([ImageId])
REFERENCES [dbo].[Image] ([Id])
GO
ALTER TABLE [dbo].[ImageTag] CHECK CONSTRAINT [FK_ImageTag_ToImage]
GO
/****** Object:  StoredProcedure [dbo].[InsertJSONData]    Script Date: 5/29/2017 11:10:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertJSONData] 
	@Image [dbo].[ImageType] READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	CREATE TABLE #IT (
		[Id] [uniqueidentifier] NOT NULL,
		[ImageName] [nvarchar](150) NOT NULL,
		[Description] [nvarchar](500) NULL,
		[People] [nvarchar](max) NULL,
		[Tags] [nvarchar](max) NULL
	)
	INSERT #IT (Id, ImageName, [Description], People, Tags)
	SELECT Id, ImageName, [Description], People, Tags FROM @Image i
	WHERE NOT EXISTS (SELECT id FROM [dbo].[Image] im WHERE i.ImageName = im.ImageName)

	IF (EXISTS (SELECT Id FROM #IT))
	BEGIN
		-- Insert into Image table
		INSERT [dbo].[Image] (Id, ImageName, [Description])
		SELECT Id, ImageName, [Description] FROM #IT
		-- Insert into ImagePerson table
		INSERT [dbo].[ImagePerson] (ImageId, PersonId, [Name])
		SELECT p.ImageId, p.PersonId, p.[Name]
		FROM #IT i CROSS APPLY OPENJSON(i.People)
		WITH (   
			ImageId		uniqueidentifier '$.ImageId',
			PersonId	uniqueidentifier '$.PersonId',
			[Name]		nvarchar(150)    '$.Name'
		) AS p
		-- Insert into ImageTag table
		INSERT [dbo].[ImageTag] (ImageId, Tag)
		SELECT t.ImageId, t.Tag
		FROM #IT i CROSS APPLY OPENJSON(i.Tags)
		WITH (   
			ImageId		uniqueidentifier '$.ImageId',
			Tag			nvarchar(50)     '$.Tag'
		) AS t

		DROP TABLE #IT
	END

	SELECT * from @Image
END


GO


