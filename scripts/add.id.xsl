<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:mei="http://www.music-encoding.org/ns/mei"
  exclude-result-prefixes="xs math xd mei"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> May 8, 2020</xd:p>
      <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
      <xd:p>This adds @xml:ids to elements.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:output method="xml" indent="yes"/>
  
  <xd:doc>
    <xd:desc>
      <xd:p>The parent element's name, inside which all descendants without @xml:id will get one.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:param name="inside" select="'section'" as="xs:string"/>
  
  <xd:doc>
    <xd:desc>
      <xd:p>Start template</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template match="/">
    <xsl:apply-templates select="node()" mode="add.id">
      <xsl:with-param name="inside" tunnel="yes" select="$inside" as="xs:string"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xd:doc>
    <xd:desc>
      <xd:p>This is a generic copy template which will copy all content in all modes</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:template match="node() | @*" mode="#all">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>