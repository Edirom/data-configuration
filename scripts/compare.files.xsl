<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
  xmlns:mei="http://www.music-encoding.org/ns/mei"
  xmlns:vife="https://edirom.de/ns/xslt"
  exclude-result-prefixes="xs math xd mei"
  version="3.0">
  <xd:doc scope="stylesheet">
    <xd:desc>
      <xd:p><xd:b>Created on:</xd:b> May 13, 2020</xd:p>
      <xd:p><xd:b>Author:</xd:b> Johannes Kepper</xd:p>
      <xd:p>This stylesheet is the public API endpoint for https://music-diff.edirom.de, i.e. it compares two MEI encodings.</xd:p>
    </xd:desc>
  </xd:doc>
  <xsl:output indent="yes" method="xml"/>
  
  <xsl:variable name="harmonize.output" select="'harm.thirds-based-chords.label.plain'"/>
  <xsl:variable name="harmonize.suppress.duplicates" select="true()"/>
  
  <xsl:include href="../tools/pick.mdiv.xsl"/>
  <xsl:include href="../tools/rescore.parts.xsl"/>
  <xsl:include href="../tools/add.id.xsl"/>
  <xsl:include href="../tools/addtstamps.xsl"/>
  <xsl:include href="../tools/add.next.xsl"/>
  <xsl:include href="../tools/add.intm.xsl"/>
  <xsl:include href="../tools/disable.staves.xsl"/>
  <xsl:include href="../tools/transpose.xsl"/>
  
  <xsl:include href="../anl/determine.pitch.xsl"/>
  <xsl:include href="../anl/determine.pnum.xsl"/>
  <xsl:include href="../anl/determine.key.xsl"/>
  <xsl:include href="../anl/determine.event.density.xsl"/>
  <xsl:include href="../anl/extract.melodic.lines.xsl"/>
  <xsl:include href="../anl/interprete.harmonies.xsl"/>
  
  <xsl:include href="../data/circleOf5.xsl"/>
  <xsl:include href="../data/keyMatrix.xsl"/>
  
  <xsl:include href="../compare/identify.identity.xsl"/>
  <xsl:include href="../compare/compare.event.density.xsl"/>
  <xsl:include href="../compare/determine.variation.xsl"/>
  <xsl:include href="../compare/adjust.rel.oct.xsl"/>
  <xsl:include href="../compare/cleanupDynam.xsl"/>
  
  <xsl:variable name="first.file.raw" select="/mei:meiCorpus/mei:mei[1]" as="node()"/>
  <xsl:variable name="second.file.raw" select="/mei:meiCorpus/mei:mei[2]" as="node()"/>
  
  <xsl:variable name="first.file" as="node()">
    <xsl:variable name="rescored.parts" as="node()">
      <xsl:apply-templates select="$first.file.raw" mode="rescore.parts"/>
    </xsl:variable>
    <xsl:variable name="added.ids" as="node()">
      <xsl:apply-templates select="$rescored.parts" mode="add.id">
        <xsl:with-param name="inside" select="'section'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="added.tstamps" as="node()">
      <xsl:apply-templates select="$added.ids" mode="add.tstamps"/>
    </xsl:variable>
    <xsl:variable name="determined.key" as="node()">
      <xsl:apply-templates select="$added.tstamps" mode="determine.key"/>
    </xsl:variable>
    <xsl:variable name="determined.pitch" as="node()">
      <xsl:apply-templates select="$determined.key" mode="determine.pitch"/>
    </xsl:variable>
    <xsl:sequence select="$determined.pitch"/>
  </xsl:variable>
  
  <xsl:variable name="second.file" as="node()">
    <xsl:variable name="rescored.parts" as="node()">
      <xsl:apply-templates select="$second.file.raw" mode="rescore.parts"/>
    </xsl:variable>
    <xsl:variable name="added.ids" as="node()">
      <xsl:apply-templates select="$rescored.parts" mode="add.id">
        <xsl:with-param name="inside" select="'section'" as="xs:string" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:variable name="added.tstamps" as="node()">
      <xsl:apply-templates select="$added.ids" mode="add.tstamps"/>
    </xsl:variable>
    <xsl:variable name="determined.key" as="node()">
      <xsl:apply-templates select="$added.tstamps" mode="determine.key"/>
    </xsl:variable>
    <xsl:variable name="determined.pitch" as="node()">
      <xsl:apply-templates select="$determined.key" mode="determine.pitch"/>
    </xsl:variable>
    <xsl:sequence select="$determined.pitch"/>
  </xsl:variable>
  
  <xsl:variable name="first.file.staff.count" select="count(($first.file//mei:scoreDef)[1]//mei:staffDef)" as="xs:integer"/>
  <xsl:variable name="second.file.staff.count" select="count(($second.file//mei:scoreDef)[1]//mei:staffDef)" as="xs:integer"/>
  
  
  <xsl:template match="/">
    
    <xsl:variable name="merged.files" as="node()">
      <xsl:apply-templates select="$first.file" mode="first.pass"/>
    </xsl:variable>
    <xsl:variable name="adjusted.rel.oct" as="node()">
      <xsl:apply-templates select="$merged.files" mode="adjust.rel.oct"/>
    </xsl:variable>
    <xsl:variable name="identified.identity" as="node()">
      <xsl:apply-templates select="$adjusted.rel.oct" mode="add.invariance"/>
    </xsl:variable>
    <xsl:variable name="determined.variation" as="node()">
      <xsl:apply-templates select="$identified.identity" mode="determine.variation"/>
    </xsl:variable>
    <xsl:variable name="cleanedup.dynamics" as="node()">
      <xsl:apply-templates select="$determined.variation" mode="clean.dynamics"/>
    </xsl:variable>
    <xsl:sequence select="$cleanedup.dynamics"/>
    
  </xsl:template>
  
  
  <xsl:template match="mei:score/mei:scoreDef" mode="first.pass">
    <xsl:variable name="pos" select="count(preceding::mei:scoreDef) + 1" as="xs:integer"/>
    
    <scoreDef xmlns="http://www.music-encoding.org/ns/mei">
      <xsl:apply-templates select="@meter.count | @meter.unit | @meter.sym" mode="#current"/>
      <staffGrp label="" symbol="none" bar.thru="false">
        <staffGrp symbol="bracket" bar.thru="true">
          <xsl:apply-templates select="mei:staffGrp/node()" mode="first.pass"/>
        </staffGrp>
        <staffGrp symbol="bracket" bar.thru="true">
          <xsl:variable name="second.file.staffDefs" select="($second.file//mei:scoreDef)[$pos]//mei:staffDef" as="node()+"/>
          <xsl:apply-templates select="($second.file//mei:scoreDef)[$pos]/mei:staffGrp/node()" mode="first.pass.file.2"/>
        </staffGrp>
      </staffGrp>
    </scoreDef>
  </xsl:template>
  <xsl:template match="mei:section/mei:scoreDef" mode="first.pass"/>
  
  <xsl:template match="mei:staffDef" mode="first.pass">
    <xsl:copy>
      <xsl:apply-templates select="ancestor::mei:scoreDef/@key.sig" mode="#current"/>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:staffDef" mode="first.pass.file.2">
    <xsl:copy>
      <xsl:if test="@n = '1'">
        <xsl:attribute name="spacing" select="'40vu'"/>
      </xsl:if>
      <xsl:apply-templates select="ancestor::mei:scoreDef/@key.sig" mode="#current"/>
      <xsl:apply-templates select="node() | @*" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="mei:measure" mode="first.pass">
    <xsl:variable name="this.measure" select="." as="node()"/>
    <xsl:variable name="pos" select="count(preceding::mei:measure)" as="xs:integer"/>
    
    <xsl:variable name="corresponding.measure" select="($second.file//mei:measure)[$pos + 1]" as="node()?"/>
    
    <xsl:sequence select="vife:combineFiles-evaluatePrecedingScoreDef($this.measure,$corresponding.measure)"/>
    
    <xsl:copy>
      <xsl:apply-templates select="mei:staff | @*" mode="#current"/>
      <xsl:apply-templates select="$corresponding.measure/mei:staff" mode="first.pass.file.2"/>
      <xsl:apply-templates select="child::mei:*[not(local-name() = 'staff')]" mode="#current"/>
      <xsl:apply-templates select="$corresponding.measure/mei:*[not(local-name() = 'staff')]" mode="first.pass.file.2"/>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="mei:staffDef/@n" mode="first.pass.file.2">
    <xsl:variable name="current.n" select="xs:integer(.)" as="xs:integer"/>
    <xsl:attribute name="n" select="$current.n + $first.file.staff.count"/>        
  </xsl:template>
  <xsl:template match="mei:staff/@n" mode="first.pass">
    <xsl:next-match/>
    <xsl:attribute name="type" select="'file1'"/>
  </xsl:template>
  <xsl:template match="mei:staff/@n" mode="first.pass.file.2">
    <xsl:variable name="current.n" select="xs:integer(.)" as="xs:integer"/>
    <xsl:attribute name="n" select="$current.n + $first.file.staff.count"/>
    <xsl:attribute name="type" select="'file2'"/>
  </xsl:template>
  <xsl:template match="@staff" mode="first.pass.file.2">
    <xsl:choose>
      <xsl:when test="not(contains(.,' '))">
        <xsl:variable name="current.n" select="xs:integer(.)" as="xs:integer"/>
        <xsl:attribute name="staff" select="$current.n + $first.file.staff.count"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="tokens" select="for $token in tokenize(normalize-space(.), ' ') return (xs:string(xs:integer($token) + $first.file.staff.count))" as="xs:string+"/>
        <xsl:attribute name="staff" select="string-join($tokens, ' ')"/>
      </xsl:otherwise>
    </xsl:choose>
    
    
  </xsl:template>
  
  <xsl:template match="@start" mode="special.pushing">
    <xsl:param name="offset" tunnel="yes"/>
    <xsl:attribute name="start" select="if(string(number(.)) != 'NaN') then(number(.) + $offset) else(.)"/>
  </xsl:template>
  
  <xsl:template match="@end" mode="special.pushing">
    <xsl:param name="offset" tunnel="yes"/>
    <xsl:attribute name="end" select="if(string(number(.)) != 'NaN') then(number(.) + $offset) else(.)"/>
  </xsl:template>
  
  <xsl:template match="*:measure/@n" mode="special.pushing">
    <xsl:attribute name="n" select="number(.) + 2"/>
  </xsl:template>
  
  <xsl:function name="vife:combineFiles-evaluatePrecedingScoreDef" as="node()?">
    <xsl:param name="measure.1" as="node()"/>
    <xsl:param name="measure.2" as="node()"/>
    
    <xsl:variable name="scoreDef.1" select="$measure.1/preceding-sibling::mei:*[1][local-name() = 'scoreDef']" as="node()?"/>
    <xsl:variable name="scoreDef.2" select="$measure.2/preceding-sibling::mei:*[1][local-name() = 'scoreDef']" as="node()?"/>
    
    <xsl:if test="exists($scoreDef.1) or exists($scoreDef.2)">
      <scoreDef xmlns="http://www.music-encoding.org/ns/mei">
        
        <staffGrp symbol="none" bar.thru="false">
          <staffGrp symbol="brace" bar.thru="true">
            <xsl:choose>
              <xsl:when test="exists($scoreDef.1)">
                <xsl:apply-templates select="$scoreDef.1" mode="condenseScoreDef"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="(1 to $first.file.staff.count)">
                  <xsl:variable name="current.pos" select="." as="xs:integer"/>
                  <staffDef xmlns="http://www.music-encoding.org/ns/mei" type="unchanged" n="{$current.pos}"/>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </staffGrp>
          <staffGrp symbol="brace" bar.thru="true">
            <xsl:choose>
              <xsl:when test="exists($scoreDef.2)">
                <xsl:apply-templates select="$scoreDef.2" mode="condenseScoreDef.file2"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="(1 to $second.file.staff.count)">
                  <xsl:variable name="current.pos" select="." as="xs:integer"/>
                  <staffDef xmlns="http://www.music-encoding.org/ns/mei" type="unchanged" n="{string($current.pos + $first.file.staff.count)}"/>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </staffGrp>
        </staffGrp>
      </scoreDef>
    </xsl:if>
    
  </xsl:function>
  
  <xsl:template match="mei:scoreDef" mode="condenseScoreDef">
    <xsl:variable name="current.scoreDef" select="." as="node()"/>
    <xsl:variable name="available.staffDef.n" select="distinct-values(.//mei:staffDef/xs:integer(@n))" as="xs:integer*"/>
    <xsl:for-each select="(1 to $first.file.staff.count)">
      <xsl:variable name="current.n" select="." as="xs:integer"/>
      <xsl:choose>
        <xsl:when test="$current.scoreDef//mei:staffDef[xs:integer(@n) = $current.n]">
          <staffDef xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="$current.scoreDef/(@* except @xml:id)" mode="#current"/>
            <xsl:apply-templates select="$current.scoreDef//mei:staffDef[xs:integer(@n) = $current.n]/(@* except @xml:id)" mode="first.pass"/>
            <xsl:attribute name="n" select="$current.n"/>
          </staffDef>        
        </xsl:when>
        <xsl:otherwise>
          <staffDef xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="$current.scoreDef/(@* except @xml:id)" mode="#current"/>
            <xsl:attribute name="n" select="$current.n"/>
          </staffDef>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="mei:scoreDef" mode="condenseScoreDef.file2">
    <xsl:variable name="current.scoreDef" select="." as="node()"/>
    <xsl:variable name="available.staffDef.n" select="distinct-values(.//mei:staffDef/xs:integer(@n))" as="xs:integer*"/>
    <xsl:for-each select="(1 to $second.file.staff.count)">
      <xsl:variable name="current.n" select="." as="xs:integer"/>
      <xsl:choose>
        <xsl:when test="$current.scoreDef//mei:staffDef[xs:integer(@n) = $current.n]">
          <staffDef xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="$current.scoreDef/(@* except @xml:id)" mode="#current"/>
            <xsl:apply-templates select="$current.scoreDef//mei:staffDef[xs:integer(@n) = $current.n]/(@* except @xml:id)" mode="first.pass"/>
            <xsl:attribute name="n" select="($current.n + $first.file.staff.count)"/>
          </staffDef>        
        </xsl:when>
        <xsl:otherwise>
          <staffDef xmlns="http://www.music-encoding.org/ns/mei" n="">
            <xsl:apply-templates select="$current.scoreDef/(@* except @xml:id)" mode="#current"/>
            <xsl:attribute name="n" select="($current.n + $first.file.staff.count)"/>
          </staffDef>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
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