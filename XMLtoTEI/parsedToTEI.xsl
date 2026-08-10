<xsl:stylesheet
  xmlns="http://www.tei-c.org/ns/1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:alto="http://www.loc.gov/standards/alto/ns-v4#"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  version="2.0"
  xpath-default-namespace="http://himeros.eu/euporia"
  exclude-result-prefixes="alto">
  
  <xsl:output method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no" />
  
  <xsl:strip-space elements="*"/>
  <xsl:param name="lang" select="'und'"/>
  
  <xsl:key name="fig-by-id"
    match="apparatoFigureItem"
    use="normalize-space(replace(figId, '\s+', ''))"/>
  
  <!-- We define a particular ALTO zone from an eScriptorium XML -->
  <xsl:template name="alto-zone">
    <xsl:param name="zoneId"/>
    <zone>
      <xsl:attribute name="xml:id"><xsl:value-of select="$zoneId"/></xsl:attribute>
      <xsl:attribute name="ulx"><xsl:value-of select="@HPOS"/></xsl:attribute>
      <xsl:attribute name="uly"><xsl:value-of select="@VPOS"/></xsl:attribute>
      <xsl:attribute name="lrx"><xsl:value-of select="xs:integer(@HPOS) + xs:integer(@WIDTH)"/></xsl:attribute>
      <xsl:attribute name="lry"><xsl:value-of select="xs:integer(@VPOS) + xs:integer(@HEIGHT)"/></xsl:attribute>
      <xsl:attribute name="points">
        <xsl:variable name="coords"
          select="tokenize(normalize-space(alto:Shape/alto:Polygon/@POINTS), '\s+')"/>
        <xsl:for-each select="1 to (count($coords) div 2)">
          <xsl:variable name="i" select="."/>
          <xsl:if test="$i gt 1">
            <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:value-of select="concat($coords[2 * $i - 1], ',', $coords[2 * $i])"/>
        </xsl:for-each>
      </xsl:attribute>
    </zone>
  </xsl:template>
  
  <!-- This template manages margin text positioning -->
  <xsl:template name="margin-place">
    <xsl:param name="pageNum" as="xs:integer"/>
    <xsl:param name="inner" as="xs:boolean" select="false()"/>
    
    <xsl:choose>
      <!-- Outer page: if even page go left, else right -->
      <xsl:when test="not($inner)">
        <xsl:value-of select="if ($pageNum mod 2 = 0) then 'left' else 'right'"/>
      </xsl:when>
      
      <!-- Inner page: swap positions -->
      <xsl:otherwise>
        <xsl:value-of select="if ($pageNum mod 2 = 0) then 'right' else 'left'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="/">
    
    <xsl:processing-instruction name="teipublisher">odd="klee.odd" template="klee2.html" view="page" media="web print epub"</xsl:processing-instruction>
    
    <TEI version="3.3.0">
      
      <!-- teiHeader corpus -->
      <teiHeader>
        <fileDesc>
          <titleStmt>
            <title>Beiträge zur bildnerischen Formlehre.</title>
          </titleStmt>
          <publicationStmt>
            <publisher>Istituto Italiano di Studi Germanici - IISG</publisher>
          </publicationStmt>
          <sourceDesc/>
        </fileDesc>
        <encodingDesc>
          <tagsDecl>
            <rendition source="klee.css"/>
          </tagsDecl>
        </encodingDesc>
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
            <xsl:variable name="altoPath" select="concat('data/', $fid, '.xml')"/>
            <xsl:variable name="altoDoc" select="if (doc-available($altoPath)) then document($altoPath) else ()"/>
            <surface>
              <xsl:attribute name="xml:id">
                <xsl:value-of select="concat('f', $fid)" />
              </xsl:attribute>
              <xsl:attribute name="ulx">0</xsl:attribute>
              <xsl:attribute name="uly">0</xsl:attribute>
              <xsl:attribute name="lrx"><xsl:value-of select="$altoDoc//alto:Page/@WIDTH"/></xsl:attribute>
              <xsl:attribute name="lry"><xsl:value-of select="$altoDoc//alto:Page/@HEIGHT"/></xsl:attribute>
              <graphic>
                <xsl:attribute name="url">
                  <xsl:value-of select="concat('https://escriptorium.d4science.org/media/documents/3/', $fid, '.jpg')"/>
                </xsl:attribute>
              </graphic>
              <!-- Zones derived from ALTO MusicZone tags -->
              <xsl:if test="$altoDoc">
                <xsl:for-each select="$altoDoc//alto:OtherTag[@LABEL = 'MusicZone']">
                  <xsl:variable name="tagId" select="@ID"/>
                  <xsl:variable name="musicOrdinal" select="position()"/>
                  <xsl:for-each select="$altoDoc//alto:TextBlock[@TAGREFS = $tagId]">
                    <xsl:call-template name="alto-zone">
                      <xsl:with-param name="zoneId" select="concat('zone_f', $fid, '_music', $musicOrdinal)"/>
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:for-each>
                <xsl:for-each select="$altoDoc//alto:OtherTag[matches(@LABEL, '^GraphicZone:figure#\d+$')]">
                  <xsl:variable name="tagId" select="@ID"/>
                  <xsl:variable name="figOrdinal"
                    select="xs:integer(replace(@LABEL, '^GraphicZone:figure#(\d+)$', '$1'))"/>
                  <xsl:for-each select="$altoDoc//alto:TextBlock[@TAGREFS = $tagId]">
                    <xsl:variable name="blockPos" select="position()"/>
                    <xsl:variable name="blockCount" select="last()"/>
                    <xsl:call-template name="alto-zone">
                      <xsl:with-param name="zoneId">
                        <xsl:value-of select="concat('zone_f', $fid, '_fig', $figOrdinal)"/>
                        <!-- append a suffix only if this figure tag maps to more than one physical block -->
                        <xsl:if test="$blockCount gt 1">
                          <xsl:value-of select="concat('_', $blockPos)"/>
                        </xsl:if>
                      </xsl:with-param>
                    </xsl:call-template>
                  </xsl:for-each>
                </xsl:for-each>
              </xsl:if>
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
        <text>
          <body>
            <xsl:variable name="flatBody">
              <xsl:apply-templates/>
            </xsl:variable>
            <xsl:call-template name="nest-headings">
              <xsl:with-param name="nodes" select="$flatBody/node()"/>
            </xsl:call-template>
          </body>
        </text>
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
    phiSub/text()             |
    operation/text()          |
    substitution/text()       |
    mrgTextZoneUp/text()      |
    mrgTextZoneOut/text()     |
    expl/text()
                  "/>
  
  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>
  
  <xsl:template match="
    apparatoFigure |
    placeholder" />
  
  <!-- Managing punctuation -->
  
  <xsl:template name="render-punct">
    <xsl:param name="char"/>
    <xsl:param name="mode" select="''"/>
    
    <pc>
      <!-- Which type of punctuation -->
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
          <xsl:when test="$char = '/'">slash</xsl:when>
          <xsl:otherwise>punct</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      
      <!-- Where it joins -->
      <xsl:if test="$char != '*'">
        <xsl:attribute name="float">
          <xsl:choose>
            <xsl:when test="$char = ('.', ',', ';', ':', '!', '?', ')', ']', '»', '…', '...')">left</xsl:when>
            <xsl:when test="$char = ('(', '[', '«')">right</xsl:when>
            <xsl:otherwise>both</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      
      <!-- How strong it is -->
      <xsl:attribute name="force">
        <xsl:choose>
          <xsl:when test="$char = ('.', '!', '?', '…', '...')">strong</xsl:when>
          <xsl:when test="$char = (',', ';', ':')">weak</xsl:when>
          <xsl:when test="$char = ('-', '–', '—', '/', '(', ')', '[', ']', '«', '»')">inter</xsl:when>
          <xsl:otherwise>inter</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      
      <xsl:value-of select="$char"/>
      
    </pc>
    
  </xsl:template>
  
  <!-- Main structure -->
  <xsl:template match="*[local-name()='div']">
    <!-- The source div is just a per-scan grouping (one per <page>); real
         sectioning comes from <head>/@n via nest-headings below, so we
         simply flatten through here instead of emitting a div ourselves. -->
    <xsl:apply-templates/>
  </xsl:template>
  
  <!--
       Turns the flat sequence of <head>/<pb>/<ab>/... produced above into
       properly nested <div>s, one per section, with the section <head> as
       its first child.
  -->
  <xsl:template name="nest-headings">
    <xsl:param name="nodes" as="node()*"/>
    
    <!-- If I want to exclude margin headings, just add "[not(@type = 'margin')]" 
         in the select below (after [local-name() = 'head']) -->
    <xsl:variable name="headLevels"
      select="for $h in $nodes[local-name() = 'head']
        return xs:integer($h/@n)"/>
    
    <xsl:choose>
      <xsl:when test="empty($headLevels)">
        <xsl:sequence select="$nodes"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="minLevel" select="min($headLevels)"/>
        <!-- A <pb> immediately followed by the boundary head belongs to the
             page the NEW section starts on, not to the section that is
             ending, so it must open the new group together with that head
             (pb first, then head) rather than trail off the previous one. -->
        <xsl:for-each-group select="$nodes"
          group-starting-with="
            *[local-name() = 'pb'][following-sibling::*[1]
              [local-name() = 'head'][not(@type = 'margin')][xs:integer(@n) = $minLevel]]
            | *[local-name() = 'head'][not(@type = 'margin')][xs:integer(@n) = $minLevel]
            [not(preceding-sibling::*[1][local-name() = 'pb'])]">
          <xsl:choose>
            <xsl:when test="local-name() = 'head' and not(@type = 'margin') and xs:integer(@n) = $minLevel">
              <div n="{$minLevel}">
                <xsl:if test="@type"><xsl:attribute name="type" select="@type"/></xsl:if>
                <xsl:sequence select="."/>
                <xsl:call-template name="nest-headings">
                  <xsl:with-param name="nodes" select="current-group()[position() gt 1]"/>
                </xsl:call-template>
              </div>
            </xsl:when>
            <xsl:when test="local-name() = 'pb'">
              <!-- Group starts with a pb whose very next sibling is the
                   boundary head: keep the pb as the section's own first
                   child, immediately followed by its head - both direct
                   children of the div, unwrapped. -->
              <div n="{$minLevel}">
                <xsl:if test="current-group()[2]/@type">
                  <xsl:attribute name="type" select="current-group()[2]/@type"/>
                </xsl:if>
                <xsl:sequence select="current-group()[1]"/>
                <xsl:sequence select="current-group()[2]"/>
                <xsl:call-template name="nest-headings">
                  <xsl:with-param name="nodes" select="current-group()[position() gt 2]"/>
                </xsl:call-template>
              </div>
            </xsl:when>
            <xsl:otherwise>
              <!-- Content before the first boundary head at this depth (or
                   deeper-level heads trapped between shallower siblings). -->
              <xsl:call-template name="nest-headings">
                <xsl:with-param name="nodes" select="current-group()"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="page">
    <pb>
      <xsl:attribute name="n">
        <xsl:choose>
          <xsl:when test="numbZone//num">
            <xsl:value-of select="normalize-space(numbZone//num[1])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of
              select="normalize-space(
                  numbZone//seg[matches(normalize-space(.), '^\d+$')][1]
                )"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="facs">
        <xsl:value-of select="normalize-space(facsimile//num)"/>
        <xsl:text>.jpg</xsl:text>
      </xsl:attribute>
    </pb>
    
    <xsl:apply-templates select="node()[
        self::mainZone
        or self::graphZoneFig
        or self::mrgTextZoneUp
        or self::mrgTextZoneOut
        or self::hdLineMargin
        or self::apparatoFigure
      ]"/>
  </xsl:template>
  
  <xsl:template match="mainZone">
    <xsl:for-each-group select="*" group-starting-with="openPar | sectionHeading">
      <xsl:choose>
        <xsl:when test="self::openPar">
          <ab n="{position()}">
            <xsl:apply-templates select="current-group()[not(self::openPar)]"/>
          </ab>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="current-group()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each-group>
  </xsl:template>
  
  <!-- Figures -->
  
  <xsl:template match="graphZoneFig">
    <xsl:variable name="fid" select="normalize-space(replace(figId, '\s+', ''))"/>
    <xsl:variable name="item" select="key('fig-by-id', $fid)"/>
    <xsl:variable name="pageNum" select="normalize-space(ancestor::page[1]/facsimile/num)"/>
    <xsl:variable name="figOrdinal" select="count(preceding-sibling::graphZoneFig) + 1"/>
    
    <xsl:variable name="altoPath" select="concat('data/', $pageNum, '.xml')"/>
    <xsl:variable name="altoDoc" select="if (doc-available($altoPath)) then document($altoPath) else ()"/>
    
    <figure facs="#zone_f{$pageNum}_fig{$figOrdinal}">
      
      <!-- Rending figure label -->
      <xsl:if test="$item/label">
        <head rend="italic">
          <xsl:apply-templates select="$item/label" mode="fig"/>
        </head>
      </xsl:if>
      
      <!-- Initializing all values -->
      <xsl:if test="$altoDoc">
        <xsl:variable name="pageWidth" select="$altoDoc//alto:Page/@WIDTH"/>
        <xsl:variable name="pageHeight" select="$altoDoc//alto:Page/@HEIGHT"/>
        <xsl:variable name="tagId"
          select="$altoDoc//alto:OtherTag[@LABEL = concat('GraphicZone:figure#', $figOrdinal)]/@ID"/>
        <xsl:variable name="block" select="($altoDoc//alto:TextBlock[@TAGREFS = $tagId])[1]"/>
        
        <xsl:if test="$block">
          <xsl:variable name="ulx" select="xs:integer($block/@HPOS)"/>
          <xsl:variable name="uly" select="xs:integer($block/@VPOS)"/>
          <xsl:variable name="w" select="xs:integer($block/@WIDTH)"/>
          <xsl:variable name="h" select="xs:integer($block/@HEIGHT)"/>
          <xsl:variable name="coords"
            select="tokenize(normalize-space($block/alto:Shape/alto:Polygon/@POINTS), '\s+')"/>
          <xsl:variable name="widthPct" select="format-number($w div xs:integer($pageWidth) * 100, '0.##')"/>
          <xsl:variable name="leftPct" select="format-number($ulx div xs:integer($pageWidth) * 100, '0.##')"/>
          
          <!-- Creating an SVG with the proper shape from eScriptorium by all the related coordinates -->
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {$w} {$h}"
               style="display:block; width:{$widthPct}%; max-width:100%; height:auto; margin-left:{$leftPct}%;">
            <defs>
              <clipPath id="clip-zone_f{$pageNum}_fig{$figOrdinal}" clipPathUnits="userSpaceOnUse">
                <polygon>
                  <xsl:attribute name="points">
                    <xsl:for-each select="1 to (count($coords) div 2)">
                      <xsl:variable name="i" select="."/>
                      <xsl:if test="$i gt 1"><xsl:text> </xsl:text></xsl:if>
                      <!-- Relative values so they suit to the corrispective dimensions -->
                      <xsl:value-of select="concat(xs:integer($coords[2 * $i - 1]) - $ulx, ',', xs:integer($coords[2 * $i]) - $uly)"/>
                    </xsl:for-each>
                  </xsl:attribute>
                </polygon>
              </clipPath>
            </defs>
            <image href="https://escriptorium.d4science.org/media/documents/3/{$pageNum}.jpg"
                   x="{-$ulx}" y="{-$uly}" width="{$pageWidth}" height="{$pageHeight}"
                   clip-path="url(#clip-zone_f{$pageNum}_fig{$figOrdinal})"/>
          </svg>
        </xsl:if>
      </xsl:if>
      
      <xsl:if test="$item/textinfig">
        <figDesc>
          <xsl:apply-templates select="$item/textinfig" mode="fig"/>
        </figDesc>
      </xsl:if>
      
    </figure>
  </xsl:template>
  
  <xsl:template match="musicZone">
    <xsl:variable name="pageNum" select="normalize-space(ancestor::page[1]/facsimile/num)"/>
    <xsl:variable name="musicOrdinal" select="count(preceding-sibling::musicZone) + 1"/>
    
    <figure type="music" facs="#zone_f{$pageNum}_music{$musicOrdinal}">
      <head><xsl:value-of select="normalize-space(musicId)"/></head>
    </figure>
  </xsl:template>
  
  <xsl:template match="text()" mode="fig">
    <xsl:value-of select="."/>
  </xsl:template>
  
  <xsl:template match="line_app" mode="fig">
    <xsl:apply-templates mode="fig"/>
  </xsl:template>
  
  <xsl:template match="text()[normalize-space(.) = '|']" mode="fig">
    <lb />
  </xsl:template>
  
  <xsl:template match="seginfig" mode="fig">
    <w>
      <xsl:value-of select="normalize-space(.)"/>
    </w>
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="punctinfig" mode="fig">
    <xsl:variable name="char" select="normalize-space(.)"/>
    <xsl:call-template name="render-punct">
      <xsl:with-param name="char" select="$char"/>
      <xsl:with-param name="mode" select="'fig'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="textSeqinfig" mode="fig">
    <xsl:apply-templates mode="fig"/>
  </xsl:template>
  
  <xsl:template match="label" mode="fig">
    <xsl:call-template name="strip-outer-brackets">
      <xsl:with-param name="nodes" select="node()"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="textinfig" mode="fig">
    <xsl:call-template name="strip-outer-brackets">
      <xsl:with-param name="nodes" select="node()"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="strip-outer-brackets">
    <xsl:param name="nodes"/>
    <xsl:for-each select="$nodes">
      <xsl:variable name="isFirst" select="position() = 1"/>
      <xsl:variable name="isLast" select="position() = last()"/>
      <xsl:choose>
        
        <xsl:when test="($isFirst or $isLast) and self::punctinfig and normalize-space(.) = ('(', ')', '[', ']')"/>
        
        <xsl:when test="self::text() and ($isFirst or $isLast)">
          <xsl:variable name="v1" select="if ($isFirst) then replace(., '^(\s*)[\(\[]', '$1') else ."/>
          <xsl:variable name="v2" select="if ($isLast) then replace($v1, '[\)\]](\s*)$', '$1') else $v1"/>
          <xsl:value-of select="$v2"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="." mode="fig"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="operation_app" mode="fig">
    <xsl:apply-templates mode="fig"/>
  </xsl:template>
  
  <xsl:template match="underlined | underlined_app" mode="fig">
    <hi rend="underline">
      <xsl:apply-templates
        select="node()[not(self::text()[matches(., '^\s*_\s*$')])]"
        mode="fig"/>
    </hi>
  </xsl:template>
  
  <!-- End figures -->
  
  <xsl:template match="sectionHeading">
    <xsl:variable name="level" select="string-length(translate(level, ' ', ''))"/>
    <xsl:variable name="type"  select="lower-case(normalize-space(sectionType/seg))"/>
    
    <!-- First <seg> ID in document order inside <line>, only if level 1 and type is PART -->
    <xsl:variable name="firstSegId"
      select="if ($level = 1 and $type = 'part')
          then generate-id((line//*[local-name()='seg'])[1])
        else ''"/>
    
    <xsl:choose>
      <xsl:when test="$type = 'pause'">
        <trailer rend="bold" type="pause">
          <xsl:apply-templates select="line/node()">
            <xsl:with-param name="firstSegId" select="$firstSegId" tunnel="yes"/>
          </xsl:apply-templates>
        </trailer>
      </xsl:when>
      <xsl:otherwise>
        <head n="{$level}" type="{$type}">
          <xsl:apply-templates select="line/node()">
            <xsl:with-param name="firstSegId" select="$firstSegId" tunnel="yes"/>
          </xsl:apply-templates>
        </head>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="hdLineMargin">
    <!-- Navigate to get page number -->
    <xsl:variable name="pageNum"
      select="xs:integer(
          if (ancestor::page[1]/numbZone//num)
            then normalize-space(ancestor::page[1]/numbZone//num[1])
          else normalize-space(
              ancestor::page[1]/numbZone//seg[matches(normalize-space(.), '^\d+$')][1]
            )
        )"/>
    
    <xsl:variable name="marginPlace">
      <xsl:call-template name="margin-place">
        <xsl:with-param name="pageNum" select="$pageNum"/>
      </xsl:call-template>
    </xsl:variable>
    
    <!-- Intentionally NOT <head>: a TOC walker that collects every <head>
         descendant (not just a div's first child) would otherwise still
         list these margin titles as flat, unnested entries. <label> is
         the correct TEI element for a non-sectioning caption/title and is
         never treated as a heading by TOC code. -->
    <label
      type="margin"
      place="{$marginPlace}"
      rend="margin-head margin-{$marginPlace}"
      n="{string-length(translate(level, ' ', ''))}">
      <xsl:apply-templates select="line"/>
    </label>
  </xsl:template>
  
  <xsl:template match="line">
    <l>
      <xsl:attribute name="n">
        <xsl:number level="any" count="line" from="page"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </l>
  </xsl:template>
  
  <xsl:template match="textSeq">
    <xsl:apply-templates/>
  </xsl:template>
  
  <xsl:template match="mrgTextZoneLow">
    <ab type="margin" place="lower" rend="margin-lower">
      <xsl:apply-templates/>
    </ab>
  </xsl:template>
  
  <xsl:template match="mrgTextZoneUp">
    <ab type="margin" place="upper" rend="margin-upper">
      <xsl:apply-templates/>
    </ab>
  </xsl:template>
  
  <xsl:template match="mrgTextZoneIn">
    <!-- Navigate to get page number -->
    <xsl:variable name="pageNum"
      select="xs:integer(
          if (ancestor::page[1]/numbZone//num)
            then normalize-space(ancestor::page[1]/numbZone//num[1])
          else normalize-space(
              ancestor::page[1]/numbZone//seg[matches(normalize-space(.), '^\d+$')][1]
            )
        )"/>
    
    <!-- Get the right place basing on position (inner is true) -->
    <xsl:variable name="marginPlace">
      <xsl:call-template name="margin-place">
        <xsl:with-param name="pageNum" select="$pageNum"/>
        <xsl:with-param name="inner" select="true()"/>
      </xsl:call-template>
    </xsl:variable>
    <ab type="margin" place="{$marginPlace}" rend="margin-{$marginPlace}">
      <xsl:apply-templates/>
    </ab>
  </xsl:template>
  
  <xsl:template match="mrgTextZoneOut">
    <!-- Navigate to get page number -->
    <xsl:variable name="pageNum"
      select="xs:integer(
          if (ancestor::page[1]/numbZone//num)
            then normalize-space(ancestor::page[1]/numbZone//num[1])
          else normalize-space(
              ancestor::page[1]/numbZone//seg[matches(normalize-space(.), '^\d+$')][1]
            )
        )"/>
    
    <!-- Get the right place basing on position (inner is false = outer position) -->
    <xsl:variable name="marginPlace">
      <xsl:call-template name="margin-place">
        <xsl:with-param name="pageNum" select="$pageNum"/>
        <xsl:with-param name="inner" select="false()"/>
      </xsl:call-template>
    </xsl:variable>
    <ab type="margin" place="{$marginPlace}" rend="margin-{$marginPlace}">
      <xsl:apply-templates/>
    </ab>
  </xsl:template>
  
  <!-- expl = explication-->
  <xsl:template match="expl">
    <note type="explication">
      <label>
        <xsl:apply-templates select="line[1]"/>
      </label>
      <xsl:apply-templates select="line[position() > 1]"/>
    </note>
  </xsl:template>
  
  <!--
       Word-part dispatcher.
       A <seg> that contains a prefix/suffix (prefix, prefix_app, suffix,
       suffix_app) represents a word that is interrupted by an
       editorial operation (deletion, replace, addition, etc.).
       This must become one <w> containing inline markup (<sic>, <corr>...).
  -->
  <xsl:template match="*[local-name()='seg'][prefix or prefix_app or suffix or suffix_app]" priority="1">
    <xsl:param name="firstSegId" tunnel="yes" select="''"/>
    
    <!-- Usually the editorial operation (deletion, pencilAddition, etc.) wraps a
         single word-fragment (e.g. one letter), which is meant to be fused with
         the prefix/suffix into one word. Sometimes, though, it wraps a *sequence*
         of several complete words (a nested textSeq with more than one <seg>
         child) -->
    <xsl:variable name="multiTextSeq"
      select="(.//*[local-name()='textSeq'][count(*[local-name()='seg']) > 1])[1]"/>
    
    <xsl:choose>
      
      <!-- Regular case: single word-fragment glued to prefix and/or suffix -->
      <xsl:when test="not($multiTextSeq)">
        <w>
          <xsl:if test="$firstSegId != '' and generate-id(.) = $firstSegId">
            <xsl:attribute name="rend">sans</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates mode="wordpart"/>
        </w>
      </xsl:when>
      
      <!-- Split case: several words inside the operation; only the boundary
           word (first if there's a prefix, last if there's a suffix) fuses
           with the prefix/suffix text. The others become their own <w>. -->
      <xsl:otherwise>
        <xsl:variable name="thisSeg" select="."/>
        <xsl:variable name="words" select="$multiTextSeq/*[local-name()='seg']"/>
        <xsl:variable name="n" select="count($words)"/>
        <xsl:for-each select="$words">
          <xsl:variable name="pos" select="position()"/>
          <w>
            <xsl:if test="$pos = 1 and $firstSegId != '' and generate-id($thisSeg) = $firstSegId">
              <xsl:attribute name="rend">sans</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="$thisSeg" mode="wordpart">
              <xsl:with-param name="onlySegId" select="generate-id(current())" tunnel="yes"/>
              <xsl:with-param name="includePrefix" select="$pos = 1" tunnel="yes"/>
              <xsl:with-param name="includeSuffix" select="$pos = $n" tunnel="yes"/>
            </xsl:apply-templates>
          </w>
        </xsl:for-each>
      </xsl:otherwise>
      
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*[local-name()='seg']">
    <xsl:param name="firstSegId" tunnel="yes" select="''"/>
    <xsl:choose>
      <xsl:when test="*">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:otherwise>
        <w>
          <xsl:if test="$firstSegId != '' and generate-id(.) = $firstSegId">
            <xsl:attribute name="rend">sans</xsl:attribute>
          </xsl:if>
          <xsl:value-of select="replace(., '^[\s&#160;]+|[\s&#160;]+$', '')"/>
        </w>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="punct">
    <xsl:variable name="char" select="normalize-space(.)"/>
    <xsl:call-template name="render-punct">
      <xsl:with-param name="char" select="$char"/>
    </xsl:call-template>
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
    <add hand="#pencil"><xsl:apply-templates/></add>
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
    <supplied>
      <xsl:apply-templates/>
    </supplied>
  </xsl:template>
  
  <xsl:template match="phiSub">
    <choice>
      <xsl:apply-templates/>
    </choice>
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
    <xsl:param name="includePrefix" tunnel="yes" select="true()"/>
    <xsl:if test="$includePrefix">
      <xsl:value-of select="normalize-space(replace(., '\^', ''))"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="suffix | suffix_app" mode="wordpart">
    <xsl:param name="includeSuffix" tunnel="yes" select="true()"/>
    <xsl:if test="$includeSuffix">
      <xsl:value-of select="normalize-space(replace(., '\^', ''))"/>
    </xsl:if>
  </xsl:template>
  
  <!-- structural wrappers: just pass through -->
  <xsl:template match="operation | textSeq" mode="wordpart">
    <xsl:apply-templates mode="wordpart"/>
  </xsl:template>
  
  <!-- nested seg (e.g. <seg>h </seg> inside textSeq): plain text only.
       When $onlySegId is set (split-word mode) and this seg is one of
       several sibling <seg> words, only the targeted sibling renders -
       the others are silenced so each ends up in its own <w>. -->
  <xsl:template match="*[local-name()='seg']" mode="wordpart">
    <xsl:param name="onlySegId" tunnel="yes" select="''"/>
    <xsl:choose>
      <xsl:when test="*">
        <xsl:apply-templates mode="wordpart"/>
      </xsl:when>
      <xsl:when test="$onlySegId != '' and count(../*[local-name()='seg']) > 1">
        <xsl:if test="generate-id(.) = $onlySegId">
          <xsl:value-of select="normalize-space(.)"/>
        </xsl:if>
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
    <add hand="#pencil"><xsl:apply-templates mode="wordpart"/></add>
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
    <supplied>
      <xsl:apply-templates mode="wordpart"/>
    </supplied>
  </xsl:template>
  
  <xsl:template match="phiSub" mode="wordpart">
    <choice>
      <xsl:apply-templates mode="wordpart"/>
    </choice>
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