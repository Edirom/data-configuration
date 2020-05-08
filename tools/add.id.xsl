<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mei="http://www.music-encoding.org/ns/mei" 
    xmlns:custom="none"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" 
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xs math xd mei custom"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>
                <xd:b>Created on:</xd:b> Oct 10, 2014,
                <xd:b>Modified on:</xd:b> May 8, 2020
            </xd:p>
            <xd:p>
                <xd:b>Author:</xd:b> Johannes Kepper</xd:p>
            <xd:p>This stylesheet generates UUIDs for elements which need one. It does not use the uuid:randomUUID() function 
                available on Saxon PE, which draws on the underlying Java function, as this code is supposed to run on the free
                Saxon HE. Performance is surely much worse. 
            </xd:p>
        </xd:desc>
        <xd:param name="inside">
            <xd:p>The <xd:b>inside</xd:b> (tunnel) parameter holds an element's name. Inside elements of this name, all elements without an @xml:id 
                will get one.</xd:p>
        </xd:param>
    </xd:doc>
    
    <xsl:template match="mei:*" mode="add.id">
        <xsl:param name="inside" tunnel="yes" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="local-name() = $inside">
                <xsl:apply-templates select="." mode="add.id.internal"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Adds @xml:id</xd:p>
        </xd:desc>
    </xd:doc>
    <xsl:template match="mei:*[not(@xml:id)]" mode="add.id.internal">
        <xsl:copy>
            <xsl:attribute name="xml:id" select="custom:uuid(.)"/>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>
            <xd:p>generates a UUID</xd:p>
        </xd:desc>
        <xd:param name="elem">The element to which the UUID is supposed to be added</xd:param>
        <xd:return>the UUID, prefixed by an 'x'</xd:return>
    </xd:doc>
    <xsl:function name="custom:uuid" as="xs:string">
        <xsl:param name="elem" as="node()"/>
        
        <!--<xsl:variable name="date.int" select="custom:concatCodepoints(xs:string(current-date()))" as="xs:integer"/>-->
        <xsl:variable name="time.int" select="custom:concatCodepoints(xs:string(current-time()))" as="xs:integer"/>
        <!--<xsl:variable name="epoch.int" select="xs:integer(round(floor((current-dateTime() - xs:dateTime('1970-01-01T00:00:00')) div xs:dayTimeDuration('PT1S'))))" as="xs:integer"/>-->

        <xsl:variable name="prec1" select="count($elem/preceding::*) + 3" as="xs:integer"/>
        <xsl:variable name="prec2" select="count($elem/preceding-sibling::*) + 2" as="xs:integer"/>

        <xsl:variable name="id.seed" select="custom:concatCodepoints(generate-id($elem))" as="xs:integer"/>
        <xsl:variable name="name.seed" select="custom:concatCodepoints(tokenize((xs:string(document-uri($elem/root()))||'ßü'),'/')[last()])" as="xs:integer"/>

        <xsl:variable name="sum" select="$time.int * $id.seed * $name.seed * $prec1" as="xs:integer"/>
        <xsl:variable name="bloat" select="custom:bloat($sum,1)" as="xs:string"/>
        <xsl:variable name="pos" select="index-of(tokenize($bloat,'\d'),'a')[1] + $prec2" as="xs:integer"/>
        <xsl:variable name="base.string" select="substring($bloat,$pos,32)" as="xs:string"/>
        <xsl:variable name="part.1" select="substring(custom:bloat(substring($base.string,1,8),2),1,8)" as="xs:string"/>
        <xsl:variable name="part.2" select="substring(custom:bloat(substring($base.string,9,4),2),1,4)" as="xs:string"/>
        <xsl:variable name="part.3" select="substring(custom:bloat(substring($base.string,13,4),2),1,3)" as="xs:string"/>
        <xsl:variable name="part.4" select="substring(custom:bloat(substring($base.string,17,4),2),1,4)" as="xs:string"/>
        <xsl:variable name="part.5" select="substring(custom:bloat(substring($base.string,21,12),2),1,12)" as="xs:string"/>
        <xsl:variable name="uuid" select="$part.1 || '-' || $part.2 || '-4' || $part.3 || '-' || $part.4 || '-' || $part.5"/>
        
        <xsl:value-of select="'x' || $uuid"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>
            <xd:p>A simple algorithm that just bloats a string</xd:p>
        </xd:desc>
        <xd:param name="input">The input, either string or integer</xd:param>
        <xd:param name="iterations">How often the algorithm shall be applied</xd:param>
        <xd:return>the bloated string</xd:return>
    </xd:doc>
    <xsl:function name="custom:bloat" as="xs:string">
        <xsl:param name="input"/>
        <xsl:param name="iterations" as="xs:integer"/>
        
        <xsl:variable name="val" select="xs:string($input)" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$iterations gt 1">
                <xsl:value-of select="custom:bloat($val,($iterations - 1))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="custom:int2hex(custom:concatCodepoints($val))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>
            <xd:p>Converts an integer to a hex value</xd:p>
        </xd:desc>
        <xd:param name="in">the integer</xd:param>
        <xd:return>the returned hex</xd:return>
    </xd:doc>
    <xsl:function name="custom:int2hex" as="xs:string">
        <xsl:param name="in" as="xs:integer"/>
        <xsl:sequence select="if ($in eq 0) then '0' 
            else concat(if ($in gt 16) then custom:int2hex($in
            idiv 16) else '',
            substring('0123456789abcdef', ($in mod 16) +
            1, 1))"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>
            <xd:p>converts a string into a sequence of codepoints, which are then treated a string and joined together, and returned as integer</xd:p>
        </xd:desc>
        <xd:param name="str">the input string</xd:param>
        <xd:return>the output integer</xd:return>
    </xd:doc>
    <xsl:function name="custom:concatCodepoints" as="xs:integer">
        <xsl:param name="str" as="xs:string"/>
        <xsl:variable name="out" as="xs:string+">
            <xsl:for-each select="(1 to string-length($str))">
                <xsl:variable name="pos" select="position()" as="xs:integer"/>
                <xsl:value-of select="string-to-codepoints(substring($str,$pos,1))"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="xs:integer(string-join($out,'73'))"/>
    </xsl:function>
    
</xsl:stylesheet>
