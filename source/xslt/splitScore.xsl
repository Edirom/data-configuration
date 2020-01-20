<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mei="http://www.music-encoding.org/ns/mei"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:uuid="java:java.util.UUID"
    exclude-result-prefixes="xs mei uuid xd math"
    version="3.0">
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b>Jan 14 2020</xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Johannes Kepper, Ran Mo</xd:p>
            <xd:p>This XSL converts score into parts</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:output indent="yes" method="xml"/>
    
    <xsl:template match="/">
        <xsl:apply-templates select="node()"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>split score into parts</xd:desc>
    </xd:doc>
    <xsl:template match="mei:score">
        <parts xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:for-each select="mei:scoreDef/mei:staffGrp/*[local-name()='staffDef' or
                local-name()='staffGrp']">
                <xsl:variable name="partNum" select="count(preceding-sibling::mei:staffDef) +
                    count(preceding-sibling::mei:staffGrp) + 1" as="xs:integer"/>
                
                <xsl:variable name="partStaves" as="xs:string">
                    <xsl:choose>
                        <xsl:when test="local-name(.)='staffDef'">
                            <xsl:value-of select="@n"/>
                        </xsl:when>
                        <xsl:when test="local-name(.)='staffGrp'">
                            <xsl:value-of select="string(min(mei:staffDef/xs:integer(@n))) || '-' || string(max(mei:staffDef/xs:integer(@n)))"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <xsl:message select="'Part ' || $partNum || ': staff(s) ' || $partStaves"/>
                <part>
                    <xsl:attribute name="n" select="$partNum"/>
                    
                    <scoreDef>
                        <xsl:for-each select="ancestor::mei:scoreDef">
                            <xsl:copy-of select="@*"/>
                        </xsl:for-each>
                        <xsl:choose>
                            <xsl:when test="local-name(.)='staffDef'">
                                <staffGrp>
                                    <xsl:copy-of select="."/>
                                </staffGrp>
                            </xsl:when>
                            <xsl:when test="local-name(.)='staffGrp'">
                                <xsl:copy-of select="."/>
                            </xsl:when>
                        </xsl:choose>
                    </scoreDef>
                    <xsl:apply-templates
                        select="ancestor::mei:score/mei:section|ancestor::mei:score/mei:ending">
                        <xsl:with-param name="staves" select="distinct-values(descendant-or-self::mei:staffDef/@n)" as="xs:string+" tunnel="yes"/>
                    </xsl:apply-templates>
                </part>
            </xsl:for-each>
        </parts>
    </xsl:template>
    
    
    <xsl:template match="mei:section|mei:ending">
        <xsl:variable name="sectionOrEnding">
            <xsl:value-of select="local-name(.)"/>
        </xsl:variable>
        <xsl:element name="{$sectionOrEnding}" xmlns="http://www.music-encoding.org/ns/mei">
            <xsl:apply-templates select="mei:scoreDef|mei:measure"/>
        </xsl:element>
    </xsl:template>
    
    
    <xsl:template match="mei:staff">
        <xsl:param name="staves" as="xs:string+" tunnel="yes"/>
        <xsl:if test="@n = $staves">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="mei:*[@staff]">
        <xsl:param name="staves" as="xs:string+" tunnel="yes"/>
        <xsl:if test="@staff = $staves">
            <xsl:next-match/>
        </xsl:if>
    </xsl:template>
    
    
    <!-- copies xml nodes -->
    <xsl:template match="node() | @*">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>