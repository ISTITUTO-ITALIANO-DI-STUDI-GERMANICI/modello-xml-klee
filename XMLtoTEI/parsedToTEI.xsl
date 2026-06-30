<xsl:stylesheet
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="2.0"
  xpath-default-namespace="http://himeros.eu/euporia"
  exclude-result-prefixes="#all">
  
  <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" />
  
  <xsl:strip-space elements="*"/>
  <xsl:param name="lang" select="'und'"/>
  
  <xsl:template match="/">
    <TEI version="3.3.0">
      
      <!-- teiHeader corpus -->
      <teiHeader>
        <fileDesc>
          <titleStmt>
            <title></title>
          </titleStmt>
          <publicationStmt>
            <p/>
          </publicationStmt>
          <sourceDesc/>
        </fileDesc>
        <profileDesc/>
      </teiHeader>
      
      <!-- Empty standOff before TEI children -->
      <standOff/>
      
      <!-- TEI Language child -->
      <TEI version="3.3.0">
        <teiHeader>
          <fileDesc>
            <titleStmt>
              <title></title>
            </titleStmt>
            <publicationStmt>
              <p><xsl:value-of select="$lang"/></p>
            </publicationStmt>
            <sourceDesc>
              <msDesc>
                <handDesc>
                  <handNote medium="pencil" xml:id="pencil">Text written with pencil.</handNote>
                </handDesc>
              </msDesc>
            </sourceDesc>
          </fileDesc>
          <profileDesc>
            <langUsage>
              <!-- The language code is set to 'und' (undetermined) by default -->
              <language ident="{$lang}"><xsl:value-of select="$lang"/></language>
            </langUsage>
          </profileDesc>
        </teiHeader>
        <text>
          <body>
            <xsl:apply-templates/>
          </body>
        </text>
        
        <!-- Implemented facsimile -->
        <facsimile>
          <!-- Cover and inner cover (pages -2 and -1) -->
          <surface xml:id="f65281">
            <graphic url="https://escriptorium.d4science.org/media/documents/3/65281.jpg"/>
          </surface>
          <surface xml:id="f67096">
            <graphic url="https://escriptorium.d4science.org/media/documents/3/67096.jpg"/>
          </surface>
          <!-- Other pages -->
          <xsl:for-each select="//page[facsimile/num]">
            <xsl:variable name="fid" select="normalize-space(facsimile/num)"/>
            <surface>
              <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('f', $fid)" />
              </xsl:attribute>
              <graphic>
                <xsl:attribute name="url">
                  <xsl:value-of select="concat('https://escriptorium.d4science.org/media/documents/3/', $fid, '.jpg')"/>
                </xsl:attribute>
              </graphic>
            </surface>
          </xsl:for-each>
          <!-- Final three pages -->
          <surface xml:id="f83236">
            <graphic url="https://escriptorium.d4science.org/media/documents/3/83236.jpg"/>
          </surface>
          <surface xml:id="f83587">
            <graphic url="https://escriptorium.d4science.org/media/documents/3/83587.jpg"/>
          </surface>
          <surface xml:id="f83602">
            <graphic url="https://escriptorium.d4science.org/media/documents/3/83602.jpg"/>
          </surface>
        </facsimile>
        
      </TEI>
      
    </TEI>
  </xsl:template>
  
  <!-- Cleaning from Euporia symbols -->
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
    substitution/text()"/>
  
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
    facsimile"/>
  
  <!-- Main structure -->
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
        <xsl:text>#f</xsl:text>
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
    <xsl:variable name="level" select="string-length(translate(level, ' ', ''))"/>
    <xsl:variable name="type"  select="lower-case(normalize-space(sectionType/seg))"/>
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

  <xsl:template match="textSeq">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!--
       Word-part dispatcher.
       A <seg> that contains a prefix/suffix (prefix, prefix_app, suffix,
       suffix_app) represents a SINGLE word that is interrupted by an
       editorial operation (deletion, replace, addition, etc.). 
       This must become ONE <w> containing inline markup (<sic>, <corr>...).
  -->
  <xsl:template match="*[local-name()='seg'][prefix or prefix_app or suffix or suffix_app]" priority="1">
    <w>
      <xsl:apply-templates mode="wordpart"/>
    </w>
  </xsl:template>
  
  <!-- Generic seg: either recurse into children or emit a plain word -->
  <xsl:template match="*[local-name()='seg']">
    <xsl:choose>
      <xsl:when test="*">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <w><xsl:value-of select="normalize-space(.)"/></w>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="punct">
    <xsl:variable name="char" select="normalize-space(.)"/>
    <pc>
      <!-- Punctuation type -->
      <xsl:attribute name="type">
        <xsl:choose>
          <xsl:when test="$char = '.'">period</xsl:when>
          <xsl:when test="$char = ','">comma</xsl:when>
          <xsl:when test="$char = ';'">semicolon</xsl:when>
          <xsl:when test="$char = ':'">colon</xsl:when>
          <xsl:when test="$char = '!'">exclam</xsl:when>
          <xsl:when test="$char = '?'">quest</xsl:when>
          <xsl:when test="$char = ('-', '–', '—')">dash</xsl:when>
          <xsl:when test="$char = ('…', '...')">ellipsis</xsl:when>
          <xsl:when test="$char = ('(', '[')">bracketOpen</xsl:when>
          <xsl:when test="$char = (')', ']')">bracketClose</xsl:when>
          <xsl:when test="$char = '«'">quoteOpen</xsl:when>
          <xsl:when test="$char = '»'">quoteClose</xsl:when>
          <xsl:when test="$char = ('&quot;', '''')">
            <!-- straight quotes are ambiguous: decide by context -->
            <xsl:choose>
              <!-- opening if preceded by whitespace or at start -->
              <xsl:when test="not(preceding-sibling::node()[1][self::text()][not(normalize-space(.) = '')])">quoteOpen</xsl:when>
              <xsl:otherwise>quoteClose</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$char = '/'">slash</xsl:when>
          <xsl:otherwise>punct</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <!-- Where to place -->
      <xsl:attribute name="join">
        <xsl:choose>
          <xsl:when test="$char = ('.', ',', ';', ':', '!', '?', ')', ']', '»', '…', '...')">left</xsl:when>
          <xsl:when test="$char = ('(', '[', '«')">right</xsl:when>
          <xsl:when test="$char = ('&quot;', '''')">
            <xsl:choose>
              <xsl:when test="not(preceding-sibling::node()[1][self::text()][not(normalize-space(.) = '')])">right</xsl:when>
              <xsl:otherwise>left</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>both</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:value-of select="$char"/>
    </pc>
  </xsl:template>
  
  <xsl:template match="prefix | prefix_app">
    <xsl:variable name="clean" select="normalize-space(replace(., '\^', ''))"/>
    <xsl:if test="$clean != ''">
      <w type="prefix"><xsl:value-of select="$clean"/></w>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="suffix | suffix_app">
    <xsl:variable name="clean" select="normalize-space(replace(., '\^', ''))"/>
    <xsl:if test="$clean != ''">
      <w type="suffix"><xsl:value-of select="$clean"/></w>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="substitution">
    <choice><xsl:apply-templates/></choice>
  </xsl:template>
  
  <xsl:template match="deletion">
    <sic><xsl:apply-templates/></sic>
  </xsl:template>
  
  <xsl:template match="replace">
    <corr><xsl:apply-templates/></corr>
  </xsl:template>
  
  <xsl:template match="subspencilDeletion | pencilDeletion">
    <sic hand="#pencil"><xsl:apply-templates/></sic>
  </xsl:template>
  
  <xsl:template match="subspencilAddition | pencilAddition">
    <corr hand="#pencil"><xsl:apply-templates/></corr>
  </xsl:template>
  
  <xsl:template match="pencil">
    <hi hand="#pencil"><xsl:apply-templates/></hi>
  </xsl:template>
  
  <xsl:template match="addition">
    <add><xsl:apply-templates/></add>
  </xsl:template>
  
  <xsl:template match="phiDel">
    <del rend="strikethrough"><xsl:apply-templates/></del>
  </xsl:template>
  
  <xsl:template match="phiAdd">
    <add rend="overstrike"><xsl:apply-templates/></add>
  </xsl:template>
  
  <xsl:template match="underlined | underlined_app">
    <hi rend="underline">
      <xsl:apply-templates select="node()[not(self::text()[normalize-space(.) = '_'])]"/>
    </hi>
  </xsl:template>
  
  <!-- mode="wordpart"                                               -->
  <!-- Used inside a single interrupted word (see seg dispatcher     -->
  <!-- above). All templates here stay INLINE -->
  
  <!-- prefix/suffix become plain text, not their own <w> -->
  <xsl:template match="prefix | prefix_app" mode="wordpart">
    <xsl:value-of select="normalize-space(replace(., '\^', ''))"/>
  </xsl:template>
  
  <xsl:template match="suffix | suffix_app" mode="wordpart">
    <xsl:value-of select="normalize-space(replace(., '\^', ''))"/>
  </xsl:template>
  
  <!-- structural wrappers: just pass through -->
  <xsl:template match="operation | textSeq" mode="wordpart">
    <xsl:apply-templates mode="wordpart"/>
  </xsl:template>
  
  <!-- nested seg (e.g. <seg>h </seg> inside textSeq): plain text only -->
  <xsl:template match="*[local-name()='seg']" mode="wordpart">
    <xsl:choose>
      <xsl:when test="*">
        <xsl:apply-templates mode="wordpart"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="substitution" mode="wordpart">
    <choice><xsl:apply-templates mode="wordpart"/></choice>
  </xsl:template>
  
  <xsl:template match="deletion" mode="wordpart">
    <sic><xsl:apply-templates mode="wordpart"/></sic>
  </xsl:template>
  
  <xsl:template match="replace" mode="wordpart">
    <corr><xsl:apply-templates mode="wordpart"/></corr>
  </xsl:template>
  
  <xsl:template match="subspencilDeletion | pencilDeletion" mode="wordpart">
    <sic hand="#pencil"><xsl:apply-templates mode="wordpart"/></sic>
  </xsl:template>
  
  <xsl:template match="subspencilAddition | pencilAddition" mode="wordpart">
    <corr hand="#pencil"><xsl:apply-templates mode="wordpart"/></corr>
  </xsl:template>
  
  <xsl:template match="pencil" mode="wordpart">
    <hi hand="#pencil"><xsl:apply-templates mode="wordpart"/></hi>
  </xsl:template>
  
  <xsl:template match="addition" mode="wordpart">
    <add><xsl:apply-templates mode="wordpart"/></add>
  </xsl:template>
  
  <xsl:template match="phiDel" mode="wordpart">
    <del rend="strikethrough"><xsl:apply-templates mode="wordpart"/></del>
  </xsl:template>
  
  <xsl:template match="phiAdd" mode="wordpart">
    <add rend="overstrike"><xsl:apply-templates mode="wordpart"/></add>
  </xsl:template>
  
  <xsl:template match="underlined | underlined_app" mode="wordpart">
    <hi rend="underline">
      <xsl:apply-templates mode="wordpart" select="node()[not(self::text()[normalize-space(.) = '_'])]"/>
    </hi>
  </xsl:template>
  
  <!-- strip the same Euporia editorial-symbol text nodes in wordpart mode -->
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
    substitution/text()" mode="wordpart"/>
  
  <!-- fallback: plain text nodes pass through verbatim -->
  <xsl:template match="text()" mode="wordpart">
    <xsl:value-of select="replace(., '\s+', ' ')"/>
  </xsl:template>
  
</xsl:stylesheet>