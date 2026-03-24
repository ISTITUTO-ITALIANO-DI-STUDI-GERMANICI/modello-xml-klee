<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.tei-c.org/ns/1.0"
                xmlns:xml="http://www.w3.org/XML/1998/namespace"
                xpath-default-namespace="http://himeros.eu/euporia"
                exclude-result-prefixes="#all">

  <xsl:output method="xml"
              encoding="UTF-8"
              indent="yes"
              omit-xml-declaration="no"/>

  <xsl:template match="/">
    <TEI>
      <teiHeader>
        <fileDesc>
          <sourceDesc>
            <msDesc>
              <handDesc>
                <handNote medium="pencil" xml:id="pencil">Text written with pencil.</handNote>
              </handDesc>
            </msDesc>
          </sourceDesc>
        </fileDesc>
      </teiHeader>
      <text type="annotations">
        <body>
          <xsl:apply-templates/>
        </body>
      </text>
    </TEI>
  </xsl:template>

  <xsl:template match="
      deletion/text()           |
      replace/text()            |
      addition/text()           |
      subspencilAddition/text() |
      subspencilDeletion/text() |
      pencilAddition/text()     |
      pencilDeletion/text()     |
      pencil/text()             |
      phiDel/text()             |
      phiAdd/text()             |
      operation/text()          |
      substitution/text()
  "/>

  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="
      apparatoFigure |
      mrgTextZoneUp  |
      mrgTextZoneOut |
      musicZone      |
      hdLineMargin   |
      placeholder    |
      numbZone       |
      facsimile
  "/>

  <xsl:template match="*[local-name()='div']">
    <div>
      <xsl:attribute name="n">
        <xsl:value-of select="@n"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="page">
    <pb>
      <xsl:attribute name="n">
        <xsl:value-of select="normalize-space(numbZone//num)"/>
      </xsl:attribute>
      <xsl:attribute name="facs">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="normalize-space(facsimile//num)"/>
      </xsl:attribute>
    </pb>
    <xsl:apply-templates select="mainZone | graphZoneFig"/>
  </xsl:template>

  <xsl:template match="mainZone">
    <xsl:for-each-group select="*" group-starting-with="openPar">
      <xsl:choose>
        <xsl:when test="self::openPar">
          <ab type="parag" n="{position()}">
            <xsl:apply-templates select="current-group()[not(self::openPar)]"/>
          </ab>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>

  <xsl:template match="graphZoneFig">
    <figure>
      <xsl:attribute name="facs">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="normalize-space(figId)"/>
      </xsl:attribute>
    </figure>
  </xsl:template>

  <xsl:template match="sectionHeading">
    <xsl:variable name="level"
      select="string-length(translate(level, ' ', ''))"/>
    <xsl:variable name="type"
      select="lower-case(normalize-space(sectionType/seg))"/>
    <head level="{$level}" type="{$type}">
      <xsl:apply-templates select="line/node()"/>
    </head>
  </xsl:template>

  <xsl:template match="line">
    <l>
      <xsl:attribute name="n">
        <xsl:number level="any" count="line" from="mainZone"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </l>
  </xsl:template>

  <xsl:template match="*[local-name()='seg']">
    <xsl:choose>
      <xsl:when test="*">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <w>
          <xsl:value-of select="normalize-space(.)"/>
        </w>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[local-name()='punct']">
    <pc>
      <xsl:value-of select="normalize-space(.)"/>
    </pc>
  </xsl:template>

  <xsl:template match="prefix | prefix_app">
    <xsl:variable name="clean" select="normalize-space(replace(., '\^', ''))"/>
    <xsl:if test="$clean != ''">
      <w><xsl:value-of select="$clean"/></w>
    </xsl:if>
  </xsl:template>

  <xsl:template match="suffix | suffix_app">
    <xsl:variable name="clean" select="normalize-space(replace(., '\^', ''))"/>
    <xsl:if test="$clean != ''">
      <w><xsl:value-of select="$clean"/></w>
    </xsl:if>
  </xsl:template>

  <xsl:template match="substitution">
    <choice>
      <xsl:apply-templates/>
    </choice>
  </xsl:template>

  <xsl:template match="deletion">
    <sic>
      <xsl:apply-templates/>
    </sic>
  </xsl:template>

  <xsl:template match="replace">
    <corr>
      <xsl:apply-templates/>
    </corr>
  </xsl:template>

  <xsl:template match="subspencilDeletion | pencilDeletion">
    <sic hand="#pencil">
      <xsl:apply-templates/>
    </sic>
  </xsl:template>

  <xsl:template match="subspencilAddition | pencilAddition">
    <corr hand="#pencil">
      <xsl:apply-templates/>
    </corr>
  </xsl:template>

  <xsl:template match="pencil">
    <hi hand="#pencil">
      <xsl:apply-templates/>
    </hi>
  </xsl:template>

  <xsl:template match="addition">
    <add>
      <xsl:apply-templates/>
    </add>
  </xsl:template>

  <xsl:template match="phiDel">
    <del rend="strikethrough">
      <xsl:apply-templates/>
    </del>
  </xsl:template>

  <xsl:template match="phiAdd">
    <add rend="overstrike">
      <xsl:apply-templates/>
    </add>
  </xsl:template>

  <xsl:template match="underlined | underlined_app">
    <hi rend="underline">
      <xsl:apply-templates
        select="node()[not(self::text()[normalize-space(.) = '_'])]"/>
    </hi>
  </xsl:template>

</xsl:stylesheet>
