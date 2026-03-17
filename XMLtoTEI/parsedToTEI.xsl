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
  
  <!-- All'interno del TEI Header vado a descrivere lo strumento utilizzato nel caso di matite -->
  
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
  
  <xsl:template match="text()">
    <xsl:variable name="t1" select="replace(., '[-+!/]*!s?\{', '')"/>
    <xsl:variable name="t2" select="replace($t1, '\}', '')"/>
    <xsl:value-of select="$t2"/>
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
  
  
  <!-- Per ciascun gruppo iniziante con <openPar> (un paragrafo) se si incontra un openPar
       crea un blocco anonimo corrispondente con un corrispettivo numero di paragrafo che
       si resetta ad ogni mainZone. Altrimenti esegui l'apply-templates sul corpo del paragrafo -->
  
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
  
  <!-- nell'apply-templates rimuovo i "_" -->
  <xsl:template match="underlined | underlined_app">
    <hi rend="underline">
      <xsl:apply-templates
        select="node()[not(self::text()[normalize-space(.) = '_'])]"/>
    </hi>
  </xsl:template>
  
  <xsl:template match="*[local-name()='div']">
    <div>
      
      <xsl:attribute name="n">
        <xsl:value-of select="@n"/>
      </xsl:attribute>
      
      <xsl:apply-templates />
      
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
  
  <xsl:template match="substitution">
    <choice>
      <xsl:apply-templates />
    </choice>
  </xsl:template>
  
  <xsl:template match="deletion">
    <sic>
      <xsl:apply-templates />
    </sic>
  </xsl:template>
  
  <xsl:template match="replace">
    <corr>
      <xsl:apply-templates />
    </corr>
  </xsl:template>
  
  <xsl:template match="subspencilDeletion | pencilDeletion">
    <sic hand="#pencil">
      <xsl:apply-templates />
    </sic>
  </xsl:template>
  
  <xsl:template match="subspencilAddition | pencilAddition">
    <corr hand="#pencil">
      <xsl:apply-templates />
    </corr>
  </xsl:template>
  
  
  
  <xsl:template match="line">
    <l>
      <!-- è sempre utile indicare i numeri di riga per pagina -->
      <xsl:attribute name="n">
        <xsl:number level="any" count="line" from="mainZone" />
      </xsl:attribute>
      <xsl:apply-templates />
    </l>
  </xsl:template>
  
  <!-- La sintassi *[local-name()='...'] per evitare mismatching con l'altro namespace -->
  <xsl:template match="*[local-name()='punct']">
    <pc>
      <xsl:value-of select="normalize-space(.)"/>
    </pc>
  </xsl:template>
  
  <xsl:template match="*[local-name()='seg']">
    <w>
      <xsl:value-of select="normalize-space(.)"/>
    </w>
  </xsl:template>
  
</xsl:stylesheet>