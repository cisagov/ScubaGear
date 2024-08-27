<xsl:stylesheet xmlns="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                 xmlns:j="http://www.w3.org/2005/xpath-functions"
                 xmlns:m="http://csrc.nist.gov/ns/oscal/metaschema/1.0"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema"
                 xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                 xpath-default-namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                 version="3.0"
                 exclude-result-prefixes="#all">
<!-- JSON to XML conversion: pipeline -->
   <xsl:output indent="true"/>
   <!-- Processing architecture -->
   <!-- $file should be a path to the file -->
   <xsl:param name="file" as="xs:string?"/>
   <!-- or $json should be a JSON literal -->
   <xsl:param name="json" as="xs:string?"/>
   <!-- Pass in $produce=supermodel to produce OSCAL M4 supermodel intermediate format -->
   <xsl:param name="produce" as="xs:string">xml</xsl:param>
   <xsl:template name="from-json">
      <xsl:if test="matches($file, '\S') and not(unparsed-text-available($file))"
               expand-text="true">
         <nm:ERROR xmlns:nm="http://csrc.nist.gov/ns/metaschema">No file found at { $file }</nm:ERROR>
      </xsl:if>
      <xsl:variable name="source">
         <xsl:choose>
            <xsl:when test="matches($json,'\S')"><!-- $json is not empty, so we try it -->
               <xsl:try xmlns:err="http://www.w3.org/2005/xqt-errors" select="json-to-xml($json)">
                  <xsl:catch expand-text="true">
                     <nm:ERROR xmlns:nm="http://csrc.nist.gov/ns/metaschema" code="{ $err:code }">{{ $err:description }}</nm:ERROR>
                  </xsl:catch>
               </xsl:try>
            </xsl:when>
            <xsl:otherwise>
               <xsl:try xmlns:err="http://www.w3.org/2005/xqt-errors"
                         select="unparsed-text($file) ! json-to-xml(.)">
                  <xsl:catch expand-text="true">
                     <nm:ERROR xmlns:nm="http://csrc.nist.gov/ns/metaschema" code="{ $err:code }">{{ $err:description }}</nm:ERROR>
                  </xsl:catch>
               </xsl:try>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="from-xdm-json-xml">
         <xsl:with-param name="source" select="$source"/>
      </xsl:call-template>
   </xsl:template>
   <xsl:mode name="cast-md" on-no-match="shallow-copy"/>
   <xsl:template match="/">
      <nm:ERROR xmlns:nm="http://csrc.nist.gov/ns/metaschema">Error in XSLT invocation - an initial template (-it) is expected ('from-json' or 'from-xdm-json-xml'), but none is given</nm:ERROR>
   </xsl:template>
   <xsl:template name="from-xdm-json-xml" expand-text="true">
      <xsl:param name="source">
         <xsl:choose><!-- evaluating $file as URI (absolute or relative to stylesheet)-->
            <xsl:when test="exists($file)">
               <xsl:try xmlns:err="http://www.w3.org/2005/xqt-errors" select="document($file)">
                  <xsl:catch expand-text="true">
                     <nm:ERROR xmlns:nm="http://csrc.nist.gov/ns/metaschema" code="{ $err:code }">{ $err:description }</nm:ERROR>
                  </xsl:catch>
               </xsl:try>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="/"/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:param>
      <xsl:if test="empty($source/j:map)" expand-text="true">
         <nm:ERROR xmlns:nm="http://csrc.nist.gov/ns/metaschema">No XPath (XML) JSON found at { $file } - using syntax of http://www.w3.org/2005/xpath-functions</nm:ERROR>
      </xsl:if>
      <xsl:variable name="near-supermodel">
         <xsl:apply-templates select="$source/*"/>
      </xsl:variable>
      <xsl:variable name="supermodel">
         <xsl:apply-templates select="$near-supermodel/*" mode="cast-md"/>
      </xsl:variable>
      <xsl:choose>
         <xsl:when test="$produce = 'supermodel'">
            <xsl:sequence select="$supermodel"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:apply-templates select="$supermodel" mode="write-xml"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <xsl:template match="/j:map[empty(@key)]" priority="10">
      <xsl:apply-templates/>
   </xsl:template>
   <!-- JSON to XML conversion: object filters -->
   <xsl:strip-space elements="j:map j:array"/>
   <!-- METASCHEMA conversion stylesheet supports JSON -> METASCHEMA/SUPERMODEL conversion -->
   <!-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ -->
   <!-- METASCHEMA: OSCAL Assessment Plan Model (version 1.1.2) in namespace "http://csrc.nist.gov/ns/oscal/1.0"-->
   <xsl:variable as="xs:string" name="metaschema-namespace">http://csrc.nist.gov/ns/oscal/1.0</xsl:variable>
   <xsl:template match="j:map[@key='assessment-plan']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan" -->
      <assembly name="assessment-plan" key="assessment-plan" gi="assessment-plan">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">assessment-plan</xsl:attribute>
         </xsl:if>
         <xsl:if test=".. is /j:map">
            <xsl:attribute name="namespace" select="$metaschema-namespace"/>
         </xsl:if>
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='metadata']"/>
         <xsl:apply-templates select="*[@key='import-ssp']"/>
         <xsl:apply-templates select="*[@key='local-definitions']"/>
         <xsl:apply-templates select="*[@key='terms-and-conditions']"/>
         <xsl:apply-templates select="*[@key='reviewed-controls']"/>
         <xsl:apply-templates select="*[@key='assessment-subjects']"/>
         <xsl:apply-templates select="*[@key='assessment-assets']"/>
         <xsl:apply-templates select="*[@key='tasks']"/>
         <xsl:apply-templates select="*[@key='back-matter']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='metadata']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="metadata" -->
      <assembly name="metadata" key="metadata" gi="metadata">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">metadata</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='published']"/>
         <xsl:apply-templates select="*[@key='last-modified']"/>
         <xsl:apply-templates select="*[@key='version']"/>
         <xsl:apply-templates select="*[@key='oscal-version']"/>
         <xsl:apply-templates select="*[@key='revisions']"/>
         <xsl:apply-templates select="*[@key='document-ids']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='roles']"/>
         <xsl:apply-templates select="*[@key='locations']"/>
         <xsl:apply-templates select="*[@key='parties']"/>
         <xsl:apply-templates select="*[@key='responsible-parties']"/>
         <xsl:apply-templates select="*[@key='actions']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="prop" -->
      <assembly name="property" gi="prop">
         <xsl:apply-templates select="*[@key='name']"/>
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='ns']"/>
         <xsl:apply-templates select="*[@key='value']"/>
         <xsl:apply-templates select="*[@key='class']"/>
         <xsl:apply-templates select="*[@key='group']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='links']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="link" -->
      <assembly name="link" gi="link">
         <xsl:apply-templates select="*[@key='href']"/>
         <xsl:apply-templates select="*[@key='rel']"/>
         <xsl:apply-templates select="*[@key='media-type']"/>
         <xsl:apply-templates select="*[@key='resource-fragment']"/>
         <xsl:apply-templates select="*[@key='text']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='responsible-parties']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="responsible-party" -->
      <assembly name="responsible-party" gi="responsible-party">
         <xsl:apply-templates select="*[@key='role-id']"/>
         <xsl:apply-templates select="*[@key='party-uuids']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="action" -->
      <assembly name="action" gi="action">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='date']"/>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='system']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='responsible-parties']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='import-ssp']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="import-ssp" -->
      <assembly name="import-ssp" key="import-ssp" gi="import-ssp">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">import-ssp</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='href']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='components']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="component" -->
      <assembly name="system-component" gi="component">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='purpose']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='status']"/>
         <xsl:apply-templates select="*[@key='responsible-roles']"/>
         <xsl:apply-templates select="*[@key='protocols']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='responsible-roles']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="responsible-role" -->
      <assembly name="responsible-role" gi="responsible-role">
         <xsl:apply-templates select="*[@key='role-id']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='party-uuids']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='protocols']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="protocol" -->
      <assembly name="protocol" gi="protocol">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='name']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='port-ranges']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="port-range" -->
      <assembly as-type="empty" name="port-range" gi="port-range">
         <xsl:apply-templates select="*[@key='start']"/>
         <xsl:apply-templates select="*[@key='end']"/>
         <xsl:apply-templates select="*[@key='transport']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='inventory-items']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="inventory-item" -->
      <assembly name="inventory-item" gi="inventory-item">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='responsible-parties']"/>
         <xsl:apply-templates select="*[@key='implemented-components']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='users']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="user" -->
      <assembly name="system-user" gi="user">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='short-name']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='role-ids']"/>
         <xsl:apply-templates select="*[@key='authorized-privileges']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='authorized-privileges']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="authorized-privilege" -->
      <assembly name="authorized-privilege" gi="authorized-privilege">
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='functions-performed']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='objectives-and-methods']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="objectives-and-methods" -->
      <assembly name="local-objective" gi="objectives-and-methods">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='parts']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='objectives-and-methods']/j:map/j:array[@key='parts']/j:map | j:array[@key='objectives-and-methods']/j:map/j:array[@key='parts']/j:map//j:array[@key='parts']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="objectives-and-methods/part | objectives-and-methods/part//part" -->
      <assembly name="part" gi="part">
         <xsl:apply-templates select="*[@key='id']"/>
         <xsl:apply-templates select="*[@key='name']"/>
         <xsl:apply-templates select="*[@key='ns']"/>
         <xsl:apply-templates select="*[@key='class']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='prose']"/>
         <xsl:apply-templates select="*[@key='parts']"/>
         <xsl:apply-templates select="*[@key='links']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='terms-and-conditions']/j:array[@key='parts']/j:map | j:map[@key='terms-and-conditions']/j:array[@key='parts']/j:map//j:array[@key='parts']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="terms-and-conditions/part | terms-and-conditions/part//part" -->
      <assembly name="assessment-part" gi="part">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='name']"/>
         <xsl:apply-templates select="*[@key='ns']"/>
         <xsl:apply-templates select="*[@key='class']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='prose']"/>
         <xsl:apply-templates select="*[@key='parts']"/>
         <xsl:apply-templates select="*[@key='links']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='activities']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="activity" -->
      <assembly name="activity" gi="activity">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='steps']"/>
         <xsl:apply-templates select="*[@key='related-controls']"/>
         <xsl:apply-templates select="*[@key='responsible-roles']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='reviewed-controls']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="reviewed-controls" -->
      <assembly name="reviewed-controls"
                 key="reviewed-controls"
                 gi="reviewed-controls">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">reviewed-controls</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='control-selections']"/>
         <xsl:apply-templates select="*[@key='control-objective-selections']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='include-all']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="include-all" -->
      <assembly as-type="empty"
                 name="include-all"
                 key="include-all"
                 gi="include-all">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">include-all</xsl:attribute>
         </xsl:if>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='include-objectives']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="include-objective" -->
      <assembly as-type="empty"
                 name="select-objective-by-id"
                 gi="include-objective">
         <xsl:apply-templates select="*[@key='objective-id']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='exclude-objectives']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="exclude-objective" -->
      <assembly as-type="empty"
                 name="select-objective-by-id"
                 gi="exclude-objective">
         <xsl:apply-templates select="*[@key='objective-id']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='related-controls']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="related-controls" -->
      <assembly name="reviewed-controls"
                 key="related-controls"
                 gi="related-controls">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">related-controls</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='control-selections']"/>
         <xsl:apply-templates select="*[@key='control-objective-selections']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='assessment-subjects']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-subject" -->
      <assembly name="assessment-subject" gi="assessment-subject">
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-subjects']"/>
         <xsl:apply-templates select="*[@key='exclude-subjects']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='include-subjects']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="include-subject" -->
      <assembly name="select-subject-by-id" gi="include-subject">
         <xsl:apply-templates select="*[@key='subject-uuid']"/>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='exclude-subjects']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="exclude-subject" -->
      <assembly name="select-subject-by-id" gi="exclude-subject">
         <xsl:apply-templates select="*[@key='subject-uuid']"/>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-assets']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-assets" -->
      <assembly name="assessment-assets"
                 key="assessment-assets"
                 gi="assessment-assets">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">assessment-assets</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='components']"/>
         <xsl:apply-templates select="*[@key='assessment-platforms']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='tasks']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="task" -->
      <assembly name="task" gi="task">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='timing']"/>
         <xsl:apply-templates select="*[@key='dependencies']"/>
         <xsl:apply-templates select="*[@key='tasks']"/>
         <xsl:apply-templates select="*[@key='associated-activities']"/>
         <xsl:apply-templates select="*[@key='subjects']"/>
         <xsl:apply-templates select="*[@key='responsible-roles']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:array[@key='subjects']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="subject" -->
      <assembly name="assessment-subject" gi="subject">
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-subjects']"/>
         <xsl:apply-templates select="*[@key='exclude-subjects']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='back-matter']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="back-matter" -->
      <assembly name="back-matter" key="back-matter" gi="back-matter">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">back-matter</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='resources']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:string[@key='remarks']">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="remarks" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="remarks"
              key="remarks"
              gi="remarks"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">remarks</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:string[@key='remarks']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:array[@key='location-uuids']/j:string">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="location-uuid" -->
      <field collapsible="no"
              as-type="uuid"
              name="location-uuid"
              gi="location-uuid"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:array[@key='location-uuids']/j:string"
                  mode="get-value-property"
                  priority="8">
      <value as-type="uuid" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:array[@key='party-uuids']/j:string">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="party-uuid" -->
      <field collapsible="no"
              as-type="uuid"
              name="party-uuid"
              gi="party-uuid"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:array[@key='party-uuids']/j:string"
                  mode="get-value-property"
                  priority="7">
      <value as-type="uuid" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:array[@key='role-ids']/j:string">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="role-id" -->
      <field collapsible="no"
              as-type="token"
              name="role-id"
              gi="role-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:array[@key='role-ids']/j:string"
                  mode="get-value-property"
                  priority="7">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:array[@key='functions-performed']/j:string">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="function-performed" -->
      <field collapsible="no"
              as-type="string"
              name="function-performed"
              gi="function-performed"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:array[@key='functions-performed']/j:string"
                  mode="get-value-property"
                  priority="9">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:array[@key='hashes']/j:map">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="hash" -->
      <field collapsible="no" as-type="string" name="hash" gi="hash">
         <xsl:apply-templates select="*[@key='algorithm']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching hash-->
   <xsl:template match="j:array[@key='hashes']/j:map" mode="get-value-property">
      <value as-type="string" key="value" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:string[@key='uuid']"
                  priority="1"><!-- XML match="assessment-plan/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="3"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='name']" priority="1"><!-- XML match="prop/@name" -->
      <flag in-json="string"
             as-type="token"
             name="name"
             key="name"
             gi="name">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='name']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='uuid']" priority="1"><!-- XML match="prop/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='ns']" priority="1"><!-- XML match="prop/@ns" -->
      <flag in-json="string"
             as-type="uri"
             name="ns"
             key="ns"
             default="http://csrc.nist.gov/ns/oscal"
             gi="ns">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='ns']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='value']" priority="1"><!-- XML match="prop/@value" -->
      <flag in-json="string"
             as-type="string"
             name="value"
             key="value"
             gi="value">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='value']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='class']" priority="1"><!-- XML match="prop/@class" -->
      <flag in-json="string"
             as-type="token"
             name="class"
             key="class"
             gi="class">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='class']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='group']" priority="1"><!-- XML match="prop/@group" -->
      <flag in-json="string"
             as-type="token"
             name="group"
             key="group"
             gi="group">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='props']/j:map/j:string[@key='group']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='href']" priority="1"><!-- XML match="link/@href" -->
      <flag in-json="string"
             as-type="uri-reference"
             name="href"
             key="href"
             gi="href">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='href']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='rel']" priority="1"><!-- XML match="link/@rel" -->
      <flag in-json="string"
             as-type="token"
             name="rel"
             key="rel"
             gi="rel">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='rel']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='media-type']"><!-- XML match="link/@media-type" -->
      <flag in-json="string"
             as-type="string"
             name="media-type"
             key="media-type"
             gi="media-type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='media-type']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='resource-fragment']"
                  priority="1"><!-- XML match="link/@resource-fragment" -->
      <flag in-json="string"
             as-type="string"
             name="resource-fragment"
             key="resource-fragment"
             gi="resource-fragment">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='links']/j:map/j:string[@key='resource-fragment']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='document-ids']/j:map/j:string[@key='scheme'] | j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='document-ids']/j:map/j:string[@key='scheme']"
                  priority="6"><!-- XML match="assessment-plan/metadata/document-id/@scheme | assessment-plan/back-matter/resource/document-id/@scheme" -->
      <flag in-json="string"
             as-type="uri"
             name="scheme"
             key="scheme"
             gi="scheme">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='document-ids']/j:map/j:string[@key='scheme'] | j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='document-ids']/j:map/j:string[@key='scheme']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='id']"
                  priority="6"><!-- XML match="assessment-plan/metadata/role/@id" -->
      <flag in-json="string" as-type="token" name="id" key="id" gi="id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='id']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:string[@key='uuid']"
                  priority="6"><!-- XML match="assessment-plan/metadata/location/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='type'] | j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='type']"><!-- XML match="assessment-plan/metadata/location/address/@type | assessment-plan/metadata/party/address/@type" -->
      <flag in-json="string"
             as-type="token"
             name="location-type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='type'] | j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="7"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='telephone-numbers']/j:map/j:string[@key='type'] | j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='telephone-numbers']/j:map/j:string[@key='type']"
                  priority="8"><!-- XML match="assessment-plan/metadata/location/telephone-number/@type | assessment-plan/metadata/party/telephone-number/@type" -->
      <flag in-json="string"
             as-type="string"
             name="type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='telephone-numbers']/j:map/j:string[@key='type'] | j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='telephone-numbers']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='uuid']"
                  priority="6"><!-- XML match="assessment-plan/metadata/party/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='type']"
                  priority="6"><!-- XML match="assessment-plan/metadata/party/@type" -->
      <flag in-json="string"
             as-type="string"
             name="type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='external-ids']/j:map/j:string[@key='scheme']"
                  priority="8"><!-- XML match="assessment-plan/metadata/party/external-id/@scheme" -->
      <flag in-json="string"
             as-type="uri"
             name="scheme"
             key="scheme"
             gi="scheme">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='external-ids']/j:map/j:string[@key='scheme']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='responsible-parties']/j:map/j:string[@key='role-id']"
                  priority="1"><!-- XML match="responsible-party/@role-id" -->
      <flag in-json="string"
             as-type="token"
             name="role-id"
             key="role-id"
             gi="role-id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='responsible-parties']/j:map/j:string[@key='role-id']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='uuid']"
                  priority="1"><!-- XML match="action/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='date']"
                  priority="1"><!-- XML match="action/@date" -->
      <flag in-json="string"
             as-type="dateTime-with-timezone"
             name="date"
             key="date"
             gi="date">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='date']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='type']"
                  priority="1"><!-- XML match="action/@type" -->
      <flag in-json="string"
             as-type="token"
             name="type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='system']"
                  priority="1"><!-- XML match="action/@system" -->
      <flag in-json="string"
             as-type="uri"
             name="system"
             key="system"
             gi="system">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='actions']/j:map/j:string[@key='system']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='import-ssp']/j:string[@key='href']" priority="1"><!-- XML match="import-ssp/@href" -->
      <flag in-json="string"
             as-type="uri-reference"
             name="href"
             key="href"
             gi="href">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='import-ssp']/j:string[@key='href']"
                  mode="keep-value-property"
                  priority="4"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='components']/j:map/j:string[@key='uuid']"
                  priority="1"><!-- XML match="component/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='components']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='components']/j:map/j:string[@key='type']"><!-- XML match="component/@type" -->
      <flag in-json="string"
             as-type="string"
             name="system-component-type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='components']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:map[@key='status']/j:string[@key='state'] | j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:map[@key='status']/j:string[@key='state']"
                  priority="7"><!-- XML match="assessment-plan/local-definitions/component/status/@state | assessment-plan/assessment-assets/component/status/@state" -->
      <flag in-json="string"
             as-type="token"
             name="state"
             key="state"
             gi="state">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:map[@key='status']/j:string[@key='state'] | j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:map[@key='status']/j:string[@key='state']"
                  mode="keep-value-property"
                  priority="7"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='responsible-roles']/j:map/j:string[@key='role-id']"
                  priority="1"><!-- XML match="responsible-role/@role-id" -->
      <flag in-json="string"
             as-type="token"
             name="role-id"
             key="role-id"
             gi="role-id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='responsible-roles']/j:map/j:string[@key='role-id']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='protocols']/j:map/j:string[@key='uuid']"
                  priority="1"><!-- XML match="protocol/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='protocols']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='protocols']/j:map/j:string[@key='name']"
                  priority="1"><!-- XML match="protocol/@name" -->
      <flag in-json="string"
             as-type="string"
             name="name"
             key="name"
             gi="name">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='protocols']/j:map/j:string[@key='name']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map/j:number[@key='start']"
                  priority="1"><!-- XML match="port-range/@start" -->
      <flag in-json="number"
             as-type="nonNegativeInteger"
             name="start"
             key="start"
             gi="start">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map/j:number[@key='start']"
                  mode="keep-value-property"
                  priority="10"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map/j:number[@key='end']"
                  priority="1"><!-- XML match="port-range/@end" -->
      <flag in-json="number"
             as-type="nonNegativeInteger"
             name="end"
             key="end"
             gi="end">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map/j:number[@key='end']"
                  mode="keep-value-property"
                  priority="10"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map/j:string[@key='transport']"
                  priority="1"><!-- XML match="port-range/@transport" -->
      <flag in-json="string"
             as-type="token"
             name="transport"
             key="transport"
             gi="transport">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='port-ranges']/j:map/j:string[@key='transport']"
                  mode="keep-value-property"
                  priority="10"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='inventory-items']/j:map/j:string[@key='uuid']"
                  priority="1"><!-- XML match="inventory-item/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='inventory-items']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map/j:string[@key='component-uuid']"
                  priority="8"><!-- XML match="assessment-plan/local-definitions/inventory-item/implemented-component/@component-uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="component-uuid"
             key="component-uuid"
             gi="component-uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map/j:string[@key='component-uuid']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='users']/j:map/j:string[@key='uuid']" priority="1"><!-- XML match="user/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='users']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='objectives-and-methods']/j:map/j:string[@key='control-id']"><!-- XML match="objectives-and-methods/@control-id" -->
      <flag in-json="string"
             as-type="token"
             name="control-id"
             key="control-id"
             gi="control-id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='objectives-and-methods']/j:map/j:string[@key='control-id']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='id']" priority="1"><!-- XML match="part/@id" -->
      <flag in-json="string" as-type="token" name="id" key="id" gi="id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='id']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='name']" priority="1"><!-- XML match="part/@name" -->
      <flag in-json="string"
             as-type="token"
             name="name"
             key="name"
             gi="name">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='name']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='ns']" priority="1"><!-- XML match="part/@ns" -->
      <flag in-json="string"
             as-type="uri"
             name="ns"
             key="ns"
             default="http://csrc.nist.gov/ns/oscal"
             gi="ns">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='ns']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='class']" priority="1"><!-- XML match="part/@class" -->
      <flag in-json="string"
             as-type="token"
             name="class"
             key="class"
             gi="class">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='class']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='activities']/j:map/j:string[@key='uuid']"
                  priority="1"><!-- XML match="activity/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='activities']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:string[@key='uuid']"
                  priority="8"><!-- XML match="assessment-plan/local-definitions/activity/step/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:string[@key='control-id']"><!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/include-control/@control-id | assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/exclude-control/@control-id | assessment-plan/local-definitions/activity/related-controls/control-selection/include-control/@control-id | assessment-plan/local-definitions/activity/related-controls/control-selection/exclude-control/@control-id | assessment-plan/reviewed-controls/control-selection/include-control/@control-id | assessment-plan/reviewed-controls/control-selection/exclude-control/@control-id" -->
      <flag in-json="string"
             as-type="token"
             name="control-id"
             key="control-id"
             gi="control-id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:string[@key='control-id'] | j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:string[@key='control-id']"
                  mode="keep-value-property"
                  priority="14"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='include-objectives']/j:map/j:string[@key='objective-id'] | j:array[@key='exclude-objectives']/j:map/j:string[@key='objective-id']"><!-- XML match="include-objective/@objective-id | exclude-objective/@objective-id" -->
      <flag in-json="string"
             as-type="token"
             name="objective-id"
             key="objective-id"
             gi="objective-id">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='include-objectives']/j:map/j:string[@key='objective-id'] | j:array[@key='exclude-objectives']/j:map/j:string[@key='objective-id']"
                  mode="keep-value-property"
                  priority="14"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='uuid']" priority="1"><!-- XML match="part/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='name']" priority="1"><!-- XML match="part/@name" -->
      <flag in-json="string"
             as-type="token"
             name="name"
             key="name"
             gi="name">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='name']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='ns']" priority="1"><!-- XML match="part/@ns" -->
      <flag in-json="string"
             as-type="uri"
             name="ns"
             key="ns"
             default="http://csrc.nist.gov/ns/oscal"
             gi="ns">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='ns']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='class']" priority="1"><!-- XML match="part/@class" -->
      <flag in-json="string"
             as-type="token"
             name="class"
             key="class"
             gi="class">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='parts']/j:map/j:string[@key='class']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='assessment-subjects']/j:map/j:string[@key='type'] | j:array[@key='subjects']/j:map/j:string[@key='type']"
                  priority="1"><!-- XML match="assessment-subject/@type | subject/@type" -->
      <flag in-json="string"
             as-type="token"
             name="type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='assessment-subjects']/j:map/j:string[@key='type'] | j:array[@key='subjects']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="5"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='include-subjects']/j:map/j:string[@key='subject-uuid'] | j:array[@key='exclude-subjects']/j:map/j:string[@key='subject-uuid']"><!-- XML match="include-subject/@subject-uuid | exclude-subject/@subject-uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="subject-uuid"
             key="subject-uuid"
             gi="subject-uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='include-subjects']/j:map/j:string[@key='subject-uuid'] | j:array[@key='exclude-subjects']/j:map/j:string[@key='subject-uuid']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='include-subjects']/j:map/j:string[@key='type'] | j:array[@key='exclude-subjects']/j:map/j:string[@key='type']"><!-- XML match="include-subject/@type | exclude-subject/@type" -->
      <flag in-json="string"
             as-type="token"
             name="subject-type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='include-subjects']/j:map/j:string[@key='type'] | j:array[@key='exclude-subjects']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:string[@key='uuid']"
                  priority="6"><!-- XML match="assessment-plan/assessment-assets/assessment-platform/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map/j:string[@key='component-uuid']"
                  priority="8"><!-- XML match="assessment-plan/assessment-assets/assessment-platform/uses-component/@component-uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="component-uuid"
             key="component-uuid"
             gi="component-uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map/j:string[@key='component-uuid']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='tasks']/j:map/j:string[@key='uuid']" priority="1"><!-- XML match="task/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='tasks']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="5"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='tasks']/j:map/j:string[@key='type']" priority="1"><!-- XML match="task/@type" -->
      <flag in-json="string"
             as-type="token"
             name="type"
             key="type"
             gi="type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='tasks']/j:map/j:string[@key='type']"
                  mode="keep-value-property"
                  priority="5"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='on-date']/j:string[@key='date']"
                  priority="8"><!-- XML match="assessment-plan//task/timing/on-date/@date" -->
      <flag in-json="string"
             as-type="dateTime-with-timezone"
             name="date"
             key="date"
             gi="date">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='on-date']/j:string[@key='date']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='within-date-range']/j:string[@key='start']"
                  priority="8"><!-- XML match="assessment-plan//task/timing/within-date-range/@start" -->
      <flag in-json="string"
             as-type="dateTime-with-timezone"
             name="start"
             key="start"
             gi="start">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='within-date-range']/j:string[@key='start']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='within-date-range']/j:string[@key='end']"
                  priority="8"><!-- XML match="assessment-plan//task/timing/within-date-range/@end" -->
      <flag in-json="string"
             as-type="dateTime-with-timezone"
             name="end"
             key="end"
             gi="end">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='within-date-range']/j:string[@key='end']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='at-frequency']/j:number[@key='period']"
                  priority="8"><!-- XML match="assessment-plan//task/timing/at-frequency/@period" -->
      <flag in-json="number"
             as-type="positiveInteger"
             name="period"
             key="period"
             gi="period">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='at-frequency']/j:number[@key='period']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='at-frequency']/j:string[@key='unit']"
                  priority="8"><!-- XML match="assessment-plan//task/timing/at-frequency/@unit" -->
      <flag in-json="string"
             as-type="string"
             name="unit"
             key="unit"
             gi="unit">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='at-frequency']/j:string[@key='unit']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='dependencies']/j:map/j:string[@key='task-uuid']"
                  priority="7"><!-- XML match="assessment-plan//task/dependency/@task-uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="task-uuid"
             key="task-uuid"
             gi="task-uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='dependencies']/j:map/j:string[@key='task-uuid']"
                  mode="keep-value-property"
                  priority="7"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:string[@key='activity-uuid']"
                  priority="7"><!-- XML match="assessment-plan//task/associated-activity/@activity-uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="activity-uuid"
             key="activity-uuid"
             gi="activity-uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:string[@key='activity-uuid']"
                  mode="keep-value-property"
                  priority="7"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:string[@key='uuid']"
                  priority="6"><!-- XML match="assessment-plan/back-matter/resource/@uuid" -->
      <flag in-json="string"
             as-type="uuid"
             name="uuid"
             key="uuid"
             gi="uuid">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:string[@key='uuid']"
                  mode="keep-value-property"
                  priority="6"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='rlinks']/j:map/j:string[@key='href']"
                  priority="8"><!-- XML match="assessment-plan/back-matter/resource/rlink/@href" -->
      <flag in-json="string"
             as-type="uri-reference"
             name="href"
             key="href"
             gi="href">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='rlinks']/j:map/j:string[@key='href']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='rlinks']/j:map/j:string[@key='media-type']"><!-- XML match="assessment-plan/back-matter/resource/rlink/@media-type" -->
      <flag in-json="string"
             as-type="string"
             name="media-type"
             key="media-type"
             gi="media-type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='rlinks']/j:map/j:string[@key='media-type']"
                  mode="keep-value-property"
                  priority="8"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:array[@key='hashes']/j:map/j:string[@key='algorithm']"
                  priority="3"><!-- XML match="hash/@algorithm" -->
      <flag in-json="string"
             as-type="string"
             name="algorithm"
             key="algorithm"
             gi="algorithm">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:array[@key='hashes']/j:map/j:string[@key='algorithm']"
                  mode="keep-value-property"
                  priority="10"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='base64']/j:string[@key='filename']"
                  priority="7"><!-- XML match="assessment-plan/back-matter/resource/base64/@filename" -->
      <flag in-json="string"
             as-type="token"
             name="filename"
             key="filename"
             gi="filename">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='base64']/j:string[@key='filename']"
                  mode="keep-value-property"
                  priority="7"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='base64']/j:string[@key='media-type']"><!-- XML match="assessment-plan/back-matter/resource/base64/@media-type" -->
      <flag in-json="string"
             as-type="string"
             name="media-type"
             key="media-type"
             gi="media-type">
         <xsl:value-of select="."/>
      </flag>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='base64']/j:string[@key='media-type']"
                  mode="keep-value-property"
                  priority="7"><!-- Not keeping the flag here. --></xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='title']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='title']"
                  mode="get-value-property"
                  priority="4">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='published']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/published" -->
      <field collapsible="no"
              as-type="dateTime-with-timezone"
              name="published"
              key="published"
              gi="published"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">published</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='published']"
                  mode="get-value-property"
                  priority="4">
      <value as-type="dateTime-with-timezone" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='last-modified']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/last-modified" -->
      <field collapsible="no"
              as-type="dateTime-with-timezone"
              name="last-modified"
              key="last-modified"
              gi="last-modified"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">last-modified</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='last-modified']"
                  mode="get-value-property"
                  priority="4">
      <value as-type="dateTime-with-timezone" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='version']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/version" -->
      <field collapsible="no"
              as-type="string"
              name="version"
              key="version"
              gi="version"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">version</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='version']"
                  mode="get-value-property"
                  priority="4">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='oscal-version']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/oscal-version" -->
      <field collapsible="no"
              as-type="string"
              name="oscal-version"
              key="oscal-version"
              gi="oscal-version"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">oscal-version</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:string[@key='oscal-version']"
                  mode="get-value-property"
                  priority="4">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision" -->
      <assembly name="revision" gi="revision">
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='published']"/>
         <xsl:apply-templates select="*[@key='last-modified']"/>
         <xsl:apply-templates select="*[@key='version']"/>
         <xsl:apply-templates select="*[@key='oscal-version']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions" -->
      <group in-xml="SHOWN"
              gi="revisions"
              group-json="ARRAY"
              name="revision"
              key="revisions">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">revisions</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*"/>
      </group>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='published']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision/published" -->
      <field collapsible="no"
              as-type="dateTime-with-timezone"
              name="published"
              key="published"
              gi="published"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">published</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='published']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="dateTime-with-timezone" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='last-modified']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision/last-modified" -->
      <field collapsible="no"
              as-type="dateTime-with-timezone"
              name="last-modified"
              key="last-modified"
              gi="last-modified"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">last-modified</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='last-modified']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="dateTime-with-timezone" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='version']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision/version" -->
      <field collapsible="no"
              as-type="string"
              name="version"
              key="version"
              gi="version"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">version</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='version']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='oscal-version']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision/oscal-version" -->
      <field collapsible="no"
              as-type="string"
              name="oscal-version"
              key="oscal-version"
              gi="oscal-version"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">oscal-version</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:string[@key='oscal-version']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/revisions/revision/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='revisions']/j:array[@key='revisions']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='document-ids']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/document-id" -->
      <field collapsible="no"
              as-type="string"
              name="document-id"
              gi="document-id">
         <xsl:apply-templates select="*[@key='scheme']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching assessment-plan/metadata/document-id-->
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='document-ids']/j:map"
                  mode="get-value-property">
      <value as-type="string" key="identifier" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/role" -->
      <assembly name="role" gi="role">
         <xsl:apply-templates select="*[@key='id']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='short-name']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/role/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='short-name']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/role/short-name" -->
      <field collapsible="no"
              as-type="string"
              name="short-name"
              key="short-name"
              gi="short-name"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">short-name</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='short-name']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/role/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location" -->
      <assembly name="location" gi="location">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='address']"/>
         <xsl:apply-templates select="*[@key='email-addresses']"/>
         <xsl:apply-templates select="*[@key='telephone-numbers']"/>
         <xsl:apply-templates select="*[@key='urls']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/address" -->
      <assembly name="address" key="address" gi="address">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">address</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='addr-lines']"/>
         <xsl:apply-templates select="*[@key='city']"/>
         <xsl:apply-templates select="*[@key='state']"/>
         <xsl:apply-templates select="*[@key='postal-code']"/>
         <xsl:apply-templates select="*[@key='country']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:array[@key='addr-lines']/j:string"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/address/addr-line" -->
      <field collapsible="no"
              as-type="string"
              name="addr-line"
              gi="addr-line"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:array[@key='addr-lines']/j:string"
                  mode="get-value-property"
                  priority="8">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='city']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/address/city" -->
      <field collapsible="no"
              as-type="string"
              name="city"
              key="city"
              gi="city"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">city</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='city']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='state']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/address/state" -->
      <field collapsible="no"
              as-type="string"
              name="state"
              key="state"
              gi="state"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">state</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='state']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='postal-code']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/address/postal-code" -->
      <field collapsible="no"
              as-type="string"
              name="postal-code"
              key="postal-code"
              gi="postal-code"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">postal-code</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='postal-code']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='country']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/address/country" -->
      <field collapsible="no"
              as-type="string"
              name="country"
              key="country"
              gi="country"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">country</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:map[@key='address']/j:string[@key='country']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='email-addresses']/j:string"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/email-address" -->
      <field collapsible="no"
              as-type="email"
              name="email-address"
              gi="email-address"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='email-addresses']/j:string"
                  mode="get-value-property"
                  priority="7">
      <value as-type="email" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='telephone-numbers']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/telephone-number" -->
      <field collapsible="no"
              as-type="string"
              name="telephone-number"
              gi="telephone-number">
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching assessment-plan/metadata/location/telephone-number-->
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='telephone-numbers']/j:map"
                  mode="get-value-property">
      <value as-type="string" key="number" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='urls']/j:string"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/url" -->
      <field collapsible="no"
              as-type="uri"
              name="url"
              deprecated="1.1.0"
              gi="url"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='urls']/j:string"
                  mode="get-value-property"
                  priority="7">
      <value as-type="uri" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/location/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='locations']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party" -->
      <assembly name="party" gi="party">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='name']"/>
         <xsl:apply-templates select="*[@key='short-name']"/>
         <xsl:apply-templates select="*[@key='external-ids']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='email-addresses']"/>
         <xsl:apply-templates select="*[@key='telephone-numbers']"/>
         <xsl:apply-templates select="*[@key='addresses']"/>
         <xsl:apply-templates select="*[@key='location-uuids']"/>
         <xsl:apply-templates select="*[@key='member-of-organizations']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='name']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/name" -->
      <field collapsible="no"
              as-type="string"
              name="name"
              key="name"
              gi="name"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">name</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='name']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='short-name']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/short-name" -->
      <field collapsible="no"
              as-type="string"
              name="short-name"
              key="short-name"
              gi="short-name"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">short-name</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:string[@key='short-name']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='external-ids']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/external-id" -->
      <field collapsible="no"
              as-type="string"
              name="external-id"
              gi="external-id">
         <xsl:apply-templates select="*[@key='scheme']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching assessment-plan/metadata/party/external-id-->
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='external-ids']/j:map"
                  mode="get-value-property">
      <value as-type="string" key="id" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='email-addresses']/j:string"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/email-address" -->
      <field collapsible="no"
              as-type="email"
              name="email-address"
              gi="email-address"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='email-addresses']/j:string"
                  mode="get-value-property"
                  priority="7">
      <value as-type="email" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='telephone-numbers']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/telephone-number" -->
      <field collapsible="no"
              as-type="string"
              name="telephone-number"
              gi="telephone-number">
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching assessment-plan/metadata/party/telephone-number-->
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='telephone-numbers']/j:map"
                  mode="get-value-property">
      <value as-type="string" key="number" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/address" -->
      <assembly name="address" gi="address">
         <xsl:apply-templates select="*[@key='type']"/>
         <xsl:apply-templates select="*[@key='addr-lines']"/>
         <xsl:apply-templates select="*[@key='city']"/>
         <xsl:apply-templates select="*[@key='state']"/>
         <xsl:apply-templates select="*[@key='postal-code']"/>
         <xsl:apply-templates select="*[@key='country']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:array[@key='addr-lines']/j:string"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/address/addr-line" -->
      <field collapsible="no"
              as-type="string"
              name="addr-line"
              gi="addr-line"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:array[@key='addr-lines']/j:string"
                  mode="get-value-property"
                  priority="10">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='city']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/address/city" -->
      <field collapsible="no"
              as-type="string"
              name="city"
              key="city"
              gi="city"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">city</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='city']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='state']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/address/state" -->
      <field collapsible="no"
              as-type="string"
              name="state"
              key="state"
              gi="state"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">state</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='state']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='postal-code']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/address/postal-code" -->
      <field collapsible="no"
              as-type="string"
              name="postal-code"
              key="postal-code"
              gi="postal-code"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">postal-code</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='postal-code']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='country']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/address/country" -->
      <field collapsible="no"
              as-type="string"
              name="country"
              key="country"
              gi="country"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">country</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='addresses']/j:map/j:string[@key='country']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='member-of-organizations']/j:string"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/party/member-of-organization" -->
      <field collapsible="no"
              as-type="uuid"
              name="member-of-organization"
              gi="member-of-organization"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='parties']/j:map/j:array[@key='member-of-organizations']/j:string"
                  mode="get-value-property"
                  priority="7">
      <value as-type="uuid" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/responsible-party/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='actions']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/action/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='actions']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='actions']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/metadata/action/responsible-party/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='metadata']/j:array[@key='actions']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']"
                  priority="3">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions" -->
      <assembly name="local-definitions"
                 key="local-definitions"
                 gi="local-definitions">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">local-definitions</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='components']"/>
         <xsl:apply-templates select="*[@key='inventory-items']"/>
         <xsl:apply-templates select="*[@key='users']"/>
         <xsl:apply-templates select="*[@key='objectives-and-methods']"/>
         <xsl:apply-templates select="*[@key='activities']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:string[@key='purpose']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/purpose" -->
      <field collapsible="no"
              as-type="markup-line"
              name="purpose"
              key="purpose"
              gi="purpose"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">purpose</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:string[@key='purpose']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:map[@key='status']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/status" -->
      <assembly name="status" key="status" gi="status">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">status</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='state']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/responsible-role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:array[@key='protocols']/j:map/j:string[@key='title']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/component/protocol/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='components']/j:map/j:array[@key='protocols']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/inventory-item/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/inventory-item/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/inventory-item/responsible-party/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/inventory-item/implemented-component" -->
      <assembly name="implemented-component" gi="implemented-component">
         <xsl:apply-templates select="*[@key='component-uuid']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='responsible-parties']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/inventory-item/implemented-component/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="12">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/inventory-item/implemented-component/responsible-party/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='inventory-items']/j:map/j:array[@key='implemented-components']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="12">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/user/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:string[@key='short-name']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/user/short-name" -->
      <field collapsible="no"
              as-type="string"
              name="short-name"
              key="short-name"
              gi="short-name"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">short-name</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:string[@key='short-name']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="string" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/user/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/user/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:array[@key='authorized-privileges']/j:map/j:string[@key='title']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/user/authorized-privilege/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:array[@key='authorized-privileges']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:array[@key='authorized-privileges']/j:map/j:string[@key='description']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/user/authorized-privilege/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='users']/j:map/j:array[@key='authorized-privileges']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/objectives-and-methods/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/objectives-and-methods/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map//j:array[@key='parts']/j:map/j:string[@key='title']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/objectives-and-methods//part/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map//j:array[@key='parts']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <!-- matching markup-multiline value for assessment-plan/local-definitions/objectives-and-methods//part-->
   <xsl:template priority="4"
                  match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map//j:array[@key='parts']/j:map/j:string[@key='prose']">
      <field scope="local"
              _step="prose"
              _key="prose"
              _metaschema-xml-id="/assembly/oscal-control-common/part/prose"
              _metaschema-json-id="/assembly/oscal-control-common/part/prose"
              in-xml="UNWRAPPED"
              collapsible="no"
              as-type="markup-multiline"
              name="prose"
              key="prose"
              _using-name="prose"
              _in-xml-name="p ul ol pre table h1 h2 h3 h4 h5 h6"
              _in-json-name="prose">
         <value as-type="markup-multiline"
                 _metaschema-xml-id="/assembly/oscal-control-common/part/prose/PROSE"
                 _metaschema-json-id="/assembly/oscal-control-common/part/prose/PROSE"
                 in-json="string">
            <xsl:value-of select="."/>
         </value>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map//j:array[@key='parts']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/objectives-and-methods//part/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='objectives-and-methods']/j:map//j:array[@key='parts']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step" -->
      <assembly name="step" gi="step">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='reviewed-controls']"/>
         <xsl:apply-templates select="*[@key='responsible-roles']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:string[@key='title']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:string[@key='description']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:string[@key='description']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:string[@key='description']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection" -->
      <assembly name="control-selection" gi="control-selection">
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-controls']"/>
         <xsl:apply-templates select="*[@key='exclude-controls']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:string[@key='description']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="13">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="13">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map"
                  priority="13">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/include-control" -->
      <assembly name="select-control-by-id" gi="include-control">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='statement-ids']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  priority="15">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/include-control/statement-id" -->
      <field collapsible="no"
              as-type="token"
              name="statement-id"
              gi="statement-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  mode="get-value-property"
                  priority="15">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map"
                  priority="12">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/exclude-control" -->
      <assembly name="select-control-by-id" gi="exclude-control">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='statement-ids']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  priority="14">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-selection/exclude-control/statement-id" -->
      <field collapsible="no"
              as-type="token"
              name="statement-id"
              gi="statement-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  mode="get-value-property"
                  priority="14">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-objective-selection" -->
      <assembly name="control-objective-selection" gi="control-objective-selection">
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-objectives']"/>
         <xsl:apply-templates select="*[@key='exclude-objectives']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:string[@key='description']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-objective-selection/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="13">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/reviewed-controls/control-objective-selection/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="13">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="12">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/step/responsible-role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='steps']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="12">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:string[@key='description']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:string[@key='description']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection" -->
      <assembly name="control-selection" gi="control-selection">
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-controls']"/>
         <xsl:apply-templates select="*[@key='exclude-controls']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:string[@key='description']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection/include-control" -->
      <assembly name="select-control-by-id" gi="include-control">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='statement-ids']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  priority="13">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection/include-control/statement-id" -->
      <field collapsible="no"
              as-type="token"
              name="statement-id"
              gi="statement-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  mode="get-value-property"
                  priority="13">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection/exclude-control" -->
      <assembly name="select-control-by-id" gi="exclude-control">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='statement-ids']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  priority="12">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-selection/exclude-control/statement-id" -->
      <field collapsible="no"
              as-type="token"
              name="statement-id"
              gi="statement-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  mode="get-value-property"
                  priority="12">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-objective-selections']/j:map"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-objective-selection" -->
      <assembly name="control-objective-selection" gi="control-objective-selection">
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-objectives']"/>
         <xsl:apply-templates select="*[@key='exclude-objectives']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-objective-selections']/j:map/j:string[@key='description']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-objective-selection/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-objective-selections']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-objective-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/related-controls/control-objective-selection/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:map[@key='related-controls']/j:array[@key='control-objective-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/local-definitions/activity/responsible-role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='local-definitions']/j:array[@key='activities']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='terms-and-conditions']"
                  priority="3">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/terms-and-conditions" -->
      <assembly name="terms-and-conditions"
                 key="terms-and-conditions"
                 gi="terms-and-conditions">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">terms-and-conditions</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='parts']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='terms-and-conditions']//j:array[@key='parts']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/terms-and-conditions//part/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='terms-and-conditions']//j:array[@key='parts']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <!-- matching markup-multiline value for assessment-plan/terms-and-conditions//part-->
   <xsl:template priority="3"
                  match="j:map[@key='assessment-plan']/j:map[@key='terms-and-conditions']//j:array[@key='parts']/j:map/j:string[@key='prose']">
      <field scope="local"
              _step="prose"
              _key="prose"
              _metaschema-xml-id="/assembly/oscal-assessment-common/assessment-part/prose"
              _metaschema-json-id="/assembly/oscal-assessment-common/assessment-part/prose"
              in-xml="UNWRAPPED"
              collapsible="no"
              as-type="markup-multiline"
              name="prose"
              key="prose"
              _using-name="prose"
              _in-xml-name="p ul ol pre table h1 h2 h3 h4 h5 h6"
              _in-json-name="prose">
         <value as-type="markup-multiline"
                 _metaschema-xml-id="/assembly/oscal-assessment-common/assessment-part/prose/PROSE"
                 _metaschema-json-id="/assembly/oscal-assessment-common/assessment-part/prose/PROSE"
                 in-json="string">
            <xsl:value-of select="."/>
         </value>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='terms-and-conditions']//j:array[@key='parts']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/terms-and-conditions//part/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='terms-and-conditions']//j:array[@key='parts']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:string[@key='description']"
                  priority="4">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:string[@key='description']"
                  mode="get-value-property"
                  priority="4">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection" -->
      <assembly name="control-selection" gi="control-selection">
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-controls']"/>
         <xsl:apply-templates select="*[@key='exclude-controls']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection/include-control" -->
      <assembly name="select-control-by-id" gi="include-control">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='statement-ids']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection/include-control/statement-id" -->
      <field collapsible="no"
              as-type="token"
              name="statement-id"
              gi="statement-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='include-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  mode="get-value-property"
                  priority="10">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection/exclude-control" -->
      <assembly name="select-control-by-id" gi="exclude-control">
         <xsl:apply-templates select="*[@key='control-id']"/>
         <xsl:apply-templates select="*[@key='statement-ids']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-selection/exclude-control/statement-id" -->
      <field collapsible="no"
              as-type="token"
              name="statement-id"
              gi="statement-id"
              in-json="SCALAR">
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-selections']/j:map/j:array[@key='exclude-controls']/j:map/j:array[@key='statement-ids']/j:string"
                  mode="get-value-property"
                  priority="9">
      <value as-type="token" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-objective-selection" -->
      <assembly name="control-objective-selection" gi="control-objective-selection">
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='include-all']"/>
         <xsl:apply-templates select="*[@key='include-objectives']"/>
         <xsl:apply-templates select="*[@key='exclude-objectives']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-objective-selection/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/reviewed-controls/control-objective-selection/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='reviewed-controls']/j:array[@key='control-objective-selections']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:string[@key='description']"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-subject/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="5">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:array[@key='include-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-subject/include-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:array[@key='include-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:array[@key='exclude-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-subject/exclude-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:array[@key='assessment-subjects']/j:map/j:array[@key='exclude-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:string[@key='purpose']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/purpose" -->
      <field collapsible="no"
              as-type="markup-line"
              name="purpose"
              key="purpose"
              gi="purpose"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">purpose</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:string[@key='purpose']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:map[@key='status']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/status" -->
      <assembly name="status" key="status" gi="status">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">status</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='state']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/responsible-role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:array[@key='protocols']/j:map/j:string[@key='title']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/component/protocol/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='components']/j:map/j:array[@key='protocols']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/assessment-platform" -->
      <assembly name="assessment-platform" gi="assessment-platform">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='uses-components']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/assessment-platform/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="8">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/assessment-platform/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="8">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/assessment-platform/uses-component" -->
      <assembly name="uses-component" gi="uses-component">
         <xsl:apply-templates select="*[@key='component-uuid']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='responsible-parties']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="10">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/assessment-platform/uses-component/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="10">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="12">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/assessment-assets/assessment-platform/uses-component/responsible-party/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='assessment-assets']/j:array[@key='assessment-platforms']/j:map/j:array[@key='uses-components']/j:map/j:array[@key='responsible-parties']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="12">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:string[@key='title']"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="5">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:string[@key='description']"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="5">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/timing" -->
      <assembly name="timing" key="timing" gi="timing">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">timing</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='on-date']"/>
         <xsl:apply-templates select="*[@key='within-date-range']"/>
         <xsl:apply-templates select="*[@key='at-frequency']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='on-date']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/timing/on-date" -->
      <assembly as-type="empty" name="on-date" key="on-date" gi="on-date">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">on-date</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='date']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='within-date-range']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/timing/within-date-range" -->
      <assembly as-type="empty"
                 name="within-date-range"
                 key="within-date-range"
                 gi="within-date-range">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">within-date-range</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='start']"/>
         <xsl:apply-templates select="*[@key='end']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:map[@key='timing']/j:map[@key='at-frequency']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/timing/at-frequency" -->
      <assembly as-type="empty"
                 name="at-frequency"
                 key="at-frequency"
                 gi="at-frequency">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">at-frequency</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='period']"/>
         <xsl:apply-templates select="*[@key='unit']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='dependencies']/j:map"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/dependency" -->
      <assembly name="dependency" gi="dependency">
         <xsl:apply-templates select="*[@key='task-uuid']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity" -->
      <assembly name="associated-activity" gi="associated-activity">
         <xsl:apply-templates select="*[@key='activity-uuid']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
         <xsl:apply-templates select="*[@key='responsible-roles']"/>
         <xsl:apply-templates select="*[@key='subjects']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity/responsible-role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:string[@key='description']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity/subject/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity/subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:array[@key='include-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="14">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity/subject/include-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:array[@key='include-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="14">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:array[@key='exclude-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="13">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/associated-activity/subject/exclude-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='associated-activities']/j:map/j:array[@key='subjects']/j:map/j:array[@key='exclude-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="13">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:string[@key='description']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/subject/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:array[@key='include-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="12">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/subject/include-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:array[@key='include-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="12">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:array[@key='exclude-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="11">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/subject/exclude-subject/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='subjects']/j:map/j:array[@key='exclude-subjects']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="11">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan//task/responsible-role/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']//j:array[@key='tasks']/j:map/j:array[@key='responsible-roles']/j:map/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map"
                  priority="5">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource" -->
      <assembly name="resource" gi="resource">
         <xsl:apply-templates select="*[@key='uuid']"/>
         <xsl:apply-templates select="*[@key='title']"/>
         <xsl:apply-templates select="*[@key='description']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='document-ids']"/>
         <xsl:apply-templates select="*[@key='citation']"/>
         <xsl:apply-templates select="*[@key='rlinks']"/>
         <xsl:apply-templates select="*[@key='base64']"/>
         <xsl:apply-templates select="*[@key='remarks']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:string[@key='title']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/title" -->
      <field collapsible="no"
              as-type="markup-line"
              name="title"
              key="title"
              gi="title"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">title</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:string[@key='title']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:string[@key='description']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/description" -->
      <field in-xml="WITH_WRAPPER"
              collapsible="no"
              as-type="markup-multiline"
              name="description"
              key="description"
              gi="description"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">description</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:string[@key='description']"
                  mode="get-value-property"
                  priority="6">
      <value as-type="markup-multiline" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='document-ids']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/document-id" -->
      <field collapsible="no"
              as-type="string"
              name="document-id"
              gi="document-id">
         <xsl:apply-templates select="*[@key='scheme']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching assessment-plan/back-matter/resource/document-id-->
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='document-ids']/j:map"
                  mode="get-value-property">
      <value as-type="string" key="identifier" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='citation']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/citation" -->
      <assembly name="citation" key="citation" gi="citation">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">citation</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='text']"/>
         <xsl:apply-templates select="*[@key='props']"/>
         <xsl:apply-templates select="*[@key='links']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='citation']/j:string[@key='text']"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/citation/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='citation']/j:string[@key='text']"
                  mode="get-value-property"
                  priority="7">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='citation']/j:array[@key='links']/j:map/j:string[@key='text']"
                  priority="9">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/citation/link/text" -->
      <field collapsible="no"
              as-type="markup-line"
              name="text"
              key="text"
              gi="text"
              in-json="SCALAR">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">text</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='citation']/j:array[@key='links']/j:map/j:string[@key='text']"
                  mode="get-value-property"
                  priority="9">
      <value as-type="markup-line" in-json="string">
         <xsl:value-of select="."/>
      </value>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:array[@key='rlinks']/j:map"
                  priority="7">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/rlink" -->
      <assembly name="rlink" gi="rlink">
         <xsl:apply-templates select="*[@key='href']"/>
         <xsl:apply-templates select="*[@key='media-type']"/>
         <xsl:apply-templates select="*[@key='hashes']"/>
      </assembly>
   </xsl:template>
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='base64']"
                  priority="6">
      <xsl:param name="with-key" select="true()"/>
      <!-- XML match="assessment-plan/back-matter/resource/base64" -->
      <field collapsible="no"
              as-type="base64Binary"
              name="base64"
              key="base64"
              gi="base64">
         <xsl:if test="$with-key">
            <xsl:attribute name="key">base64</xsl:attribute>
         </xsl:if>
         <xsl:apply-templates select="*[@key='filename']"/>
         <xsl:apply-templates select="*[@key='media-type']"/>
         <xsl:apply-templates select="." mode="get-value-property"/>
      </field>
   </xsl:template>
   <!-- matching assessment-plan/back-matter/resource/base64-->
   <xsl:template match="j:map[@key='assessment-plan']/j:map[@key='back-matter']/j:array[@key='resources']/j:map/j:map[@key='base64']"
                  mode="get-value-property">
      <value as-type="base64Binary" key="value" in-json="string">
         <xsl:apply-templates mode="keep-value-property"/>
      </value>
   </xsl:template>
   <!-- by default, fields traverse their properties to find a value -->
   <xsl:template match="*" mode="get-value-property">
      <xsl:apply-templates mode="keep-value-property"/>
   </xsl:template>
   <xsl:template match="*" mode="keep-value-property">
      <xsl:value-of select="."/>
   </xsl:template>
   <!-- JSON to XML conversion: Markdown to markup inferencing -->
   <xsl:template mode="cast-md"
                  xpath-default-namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  match="value[@as-type=('markup-line')]">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!-- if this is valid only a single p comes back but who can tell? -->
         <xsl:call-template name="parse-markdown-line">
            <xsl:with-param name="markdown-str" select="string(.)"/>
         </xsl:call-template>
      </xsl:copy>
   </xsl:template>
   <xsl:template mode="cast-md"
                  xpath-default-namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  match="value[@as-type=('markup-multiline')]">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:call-template name="parse-markdown">
            <xsl:with-param name="markdown-str" select="string(.)"/>
         </xsl:call-template>
      </xsl:copy>
   </xsl:template>
   <xsl:template name="parse-markdown-line">
      <xsl:param name="markdown-str" as="xs:string" required="yes"/>
      <xsl:variable name="str-as-textnode">
         <xsl:value-of select="string($markdown-str) =&gt; replace('\\n','&#xA;')"/>
      </xsl:variable>
      <xsl:apply-templates select="$str-as-textnode" mode="infer-inlines"/>
   </xsl:template>
   <xsl:template name="parse-markdown">
        
<!-- First, group according to ``` delimiters btw codeblocks and not
        within codeblock, escape & and < (only)
        within not-codeblock split lines at \n\s*\n
        
        -->
        <!-- $str may be passed in, or we can process the current node -->
      <xsl:param name="markdown-str" as="xs:string" required="yes"/>
      <xsl:variable name="str" select="string($markdown-str) =&gt; replace('\\n','&#xA;')"/>
      <xsl:variable name="starts-with-code" select="matches($str,'^```')"/>
      <!-- Blocks is split between code blocks and everything else -->
      <xsl:variable name="blocks">
         <xsl:for-each-group select="tokenize($str, '\n')"
                              group-starting-with=".[matches(., '^```')]">
                <!-- odd groups are code if the first one has code, otherwise evens -->
            <xsl:variable name="this-is-code"
                           select="not((position() mod 2) + number($starts-with-code))"/>
            <p><!-- Adding an attribute flag when this is a code block, code='code' -->
               <xsl:if test="$this-is-code">
                  <xsl:variable name="language"
                                 expand-text="true"
                                 select="(replace(.,'^```','') ! normalize-space(.))[matches(.,'\S')]"/>
                  <xsl:attribute name="code" select="if ($language) then $language else 'code'"/>
               </xsl:if>
               <xsl:value-of select="string-join(current-group()[not(matches(., '^```'))],'&#xA;')"/>
            </p>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="rough-blocks">
         <xsl:apply-templates select="$blocks" mode="parse-block"/>
      </xsl:variable>
      <!-- for debugging <xsl:copy-of select="$rough-blocks"/> -->
      <xsl:variable name="flat-structures">
         <xsl:apply-templates select="$rough-blocks" mode="mark-structures"/>
      </xsl:variable>
      <!-- for debugging <xsl:copy-of select="$flat-structures"/>-->
      <xsl:variable name="nested-structures">
         <xsl:apply-templates select="$flat-structures" mode="build-structures"/>
      </xsl:variable>
      <!-- for debugging <xsl:copy-of select="$nested-structures"/>-->
      <xsl:variable name="fully-marked">
         <xsl:apply-templates select="$nested-structures" mode="infer-inlines"/>
      </xsl:variable>
      <xsl:sequence select="$fully-marked"/>
   </xsl:template>
   <xsl:template match="*" mode="copy mark-structures build-structures infer-inlines">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template mode="parse-block"
                  priority="1"
                  match="p[exists(@code)]"
                  expand-text="true">
      <pre>
         <xsl:for-each select="@code[not(.='code')]">
            <xsl:attribute name="class">language-{.}</xsl:attribute>
         </xsl:for-each>
         <xsl:value-of select="string(.)"/>
      </pre>
   </xsl:template>
   <xsl:template mode="parse-block" match="p" expand-text="true">
      <xsl:for-each select="tokenize(string(.),'\n\s*\n')[normalize-space(.)]">
         <p>
                <!-- trimming leading and trailing whitespace here -->
            <xsl:value-of select="replace(.,'(^\s*\n|\s+$)','')"/>
         </p>
      </xsl:for-each>
   </xsl:template>
   <xsl:function name="m:is-table-row-demarcator" as="xs:boolean">
      <xsl:param name="line" as="xs:string"/>
      <xsl:sequence select="matches($line,'^[\|\-:\s]+$')"/>
   </xsl:function>
   <xsl:function name="m:is-table" as="xs:boolean">
      <xsl:param name="line" as="element(p)"/>
      <xsl:variable name="lines" select="tokenize($line,'\s*\n')[matches(.,'\S')]"/>
      <xsl:sequence select="(every $l in $lines satisfies matches($l,'^\|')) and (some $l in $lines satisfies m:is-table-row-demarcator($l))"/>
   </xsl:function>
   <xsl:template mode="mark-structures" priority="5" match="p[m:is-table(.)]">
      <xsl:variable name="rows">
         <xsl:for-each select="tokenize(string(.),'\s*\n')">
            <tr>
               <xsl:value-of select="."/>
            </tr>
         </xsl:for-each>
      </xsl:variable>
      <table>
         <xsl:apply-templates select="$rows/tr" mode="make-row"/>
      </table>
   </xsl:template>
   <xsl:template match="tr[m:is-table-row-demarcator(string(.))]"
                  priority="5"
                  mode="make-row"/>
   <xsl:template match="tr" mode="make-row">
      <tr>
         <xsl:for-each select="tokenize(string(.), '\s*\|\s*')[not(position() = (1,last())) ]">
            <td>
               <xsl:value-of select="."/>
            </td>
         </xsl:for-each>
      </tr>
   </xsl:template>
   <xsl:template match="tr[some $f in (following-sibling::tr) satisfies m:is-table-row-demarcator(string($f))]"
                  mode="make-row">
      <tr>
         <xsl:for-each select="tokenize(string(.), '\s*\|\s*')[not(position() = (1,last())) ]">
            <th>
               <xsl:value-of select="."/>
            </th>
         </xsl:for-each>
      </tr>
   </xsl:template>
   <xsl:template mode="mark-structures" match="p[matches(.,'^#')]">
        <!-- 's' flag is dot-matches-all, so \n does not impede -->
      <p header-level="{ replace(.,'[^#].*$','','s') ! string-length(.) }">
         <xsl:value-of select="replace(.,'^#+\s*','') ! replace(.,'\s+$','')"/>
      </p>
   </xsl:template>
   <xsl:variable name="li-regex" as="xs:string">^\s*(\*|\d+\.)\s</xsl:variable>
   <xsl:template mode="mark-structures" match="p[matches(.,$li-regex)]">
      <list>
         <xsl:for-each-group group-starting-with=".[matches(.,$li-regex)]"
                              select="tokenize(., '\n')">
            <li level="{ replace(.,'\S.*$','') ! floor(string-length(.) div 2)}"
                 type="{ if (matches(.,'\s*\d')) then 'ol' else 'ul' }">
               <xsl:for-each select="current-group()[normalize-space(.)]">
                  <xsl:if test="not(position() eq 1)">
                     <br/>
                  </xsl:if>
                  <xsl:value-of select="replace(., $li-regex, '')"/>
               </xsl:for-each>
            </li>
         </xsl:for-each-group>
      </list>
   </xsl:template>
   <xsl:template mode="build-structures" match="p[@header-level]">
      <xsl:variable name="level" select="(@header-level[6 &gt;= .],6)[1]"/>
      <xsl:element name="h{$level}"
                    namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel">
         <xsl:value-of select="."/>
      </xsl:element>
   </xsl:template>
   <xsl:template mode="build-structures" match="list" name="nest-lists">
        <!-- Starting at level 0 and grouping  -->
        <!--        -->
      <xsl:param name="level" select="0"/>
      <xsl:param name="group" select="li"/>
      <xsl:variable name="this-type" select="$group[1]/@type"/>
      <!--first, splitting ul from ol groups -->
      <!--<xsl:for-each-group select="$group" group-starting-with="*[@level = $level and not(@type = preceding-sibling::*[1]/@type)]">-->
      <!--<xsl:for-each-group select="$group" group-starting-with="*[@level = $level]">-->
      <xsl:element name="{ $group[1]/@type }"
                    namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel">
         <xsl:for-each-group select="$group"
                              group-starting-with="li[(@level = $level) or not(@type = preceding-sibling::*[1]/@type)]">
            <xsl:choose>
               <xsl:when test="@level = $level (: checking first item in group :)">
                  <li>
                            <!--<xsl:copy-of select="@level"/>-->
                     <xsl:apply-templates mode="copy"/>
                     <xsl:if test="current-group()/@level &gt; $level (: go deeper? :)">
                        <xsl:call-template name="nest-lists">
                           <xsl:with-param name="level" select="$level + 1"/>
                           <xsl:with-param name="group" select="current-group()[@level &gt; $level]"/>
                        </xsl:call-template>
                     </xsl:if>
                  </li>
               </xsl:when>
               <xsl:otherwise>
                        <!-- fallback for skipping levels -->
                  <li>
                                <!-- level="{$level}"-->
                     <xsl:call-template name="nest-lists">
                        <xsl:with-param name="level" select="$level + 1"/>
                        <xsl:with-param name="group" select="current-group()"/>
                     </xsl:call-template>
                  </li>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </xsl:element>
      <!--</xsl:for-each-group>-->
   </xsl:template>
   <xsl:template match="pre//text()" mode="infer-inlines">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="text()" mode="infer-inlines">
      <xsl:variable name="markup">
         <xsl:apply-templates select="$tag-replacements/rules" mode="replacements">
            <xsl:with-param name="original" tunnel="yes" as="text()" select="."/>
         </xsl:apply-templates>
      </xsl:variable>
      <xsl:try select="parse-xml-fragment($markup)">
         <xsl:catch select="."/>
      </xsl:try>
   </xsl:template>
   <xsl:template match="rules" as="xs:string" mode="replacements">

        <!-- Original is only provided for processing text nodes -->
      <xsl:param name="original" as="text()?" tunnel="yes"/>
      <xsl:param name="starting" as="xs:string" select="string($original)"/>
      <xsl:iterate select="*">
         <xsl:param name="original" select="$original" as="text()?"/>
         <xsl:param name="str" select="$starting" as="xs:string"/>
         <xsl:on-completion select="$str"/>
         <xsl:next-iteration>
            <xsl:with-param name="str">
               <xsl:apply-templates select="." mode="replacements">
                  <xsl:with-param name="str" select="$str"/>
               </xsl:apply-templates>
            </xsl:with-param>
         </xsl:next-iteration>
      </xsl:iterate>
   </xsl:template>
   <xsl:template match="replace" expand-text="true" mode="replacements">
      <xsl:param name="str" as="xs:string"/>
      <!--<xsl:value-of>replace({$str},{@match},{string(.)})</xsl:value-of>-->
      <!-- 's' sets dot-matches-all       -->
      <xsl:sequence select="replace($str, @match, string(.),'s')"/>
      <!--<xsl:copy-of select="."/>-->
   </xsl:template>
   <xsl:variable name="tag-replacements">
      <rules>
            <!-- first, literal replacements -->
         <replace match="&amp;">&amp;amp;</replace>
         <replace match="&lt;">&amp;lt;</replace>
         <!-- next, explicit escape sequences -->
         <replace match="\\&#34;">&amp;quot;</replace>
         <!--<replace match="\\&#39;">&amp;apos;</replace>-->
         <replace match="\\\*">&amp;#x2A;</replace>
         <replace match="\\`">&amp;#x60;</replace>
         <replace match="\\~">&amp;#x7E;</replace>
         <replace match="\\^">&amp;#x5E;</replace>
         <!-- then, replacements based on $tag-specification -->
         <xsl:for-each select="$tag-specification/*">
            <xsl:variable name="match-expr">
               <xsl:apply-templates select="." mode="write-match"/>
            </xsl:variable>
            <xsl:variable name="repl-expr">
               <xsl:apply-templates select="." mode="write-replace"/>
            </xsl:variable>
            <replace match="{$match-expr}">
               <xsl:sequence select="$repl-expr"/>
            </replace>
         </xsl:for-each>
      </rules>
   </xsl:variable>
   <xsl:variable name="tag-specification" as="element()">
      <tag-spec>
            <!-- The XML notation represents the substitution by showing both delimiters and tags  -->
            <!-- Note that text contents are regex notation for matching so * must be \* -->
         <q>"<text/>"</q>
         <img alt="!\[{{$noclosebracket}}\]" src="\({{$nocloseparen}}\)"/>
         <insert>\{\{\s*insert: <type/>,\s*<id-ref/>\s*\}\}</insert>
         <a href="\[{{$noclosebracket}}\]">\(<text not="\)"/>\)</a>
         <code>`<text/>`</code>
         <strong>
            <em>\*\*\*<text/>\*\*\*</em>
         </strong>
         <strong>\*\*<text/>\*\*</strong>
         <em>\*<text/>\*</em>
         <sub>~<text/>~</sub>
         <sup>\^<text/>\^</sup>
      </tag-spec>
   </xsl:variable>
   <xsl:template match="*" mode="write-match">
      <xsl:apply-templates select="@*, node()" mode="write-match"/>
   </xsl:template>
   <xsl:template match="@*[matches(., '\{\$text\}')]" mode="write-match">
      <xsl:value-of select="replace(., '\{\$text\}', '(.*)?')"/>
   </xsl:template>
   <xsl:template match="@*[matches(., '\{\$nocloseparen\}')]" mode="write-match">
      <xsl:value-of select="replace(., '\{\$nocloseparen\}', '([^\\(]*)?')"/>
   </xsl:template>
   <xsl:template match="@*[matches(., '\{\$noclosebracket\}')]" mode="write-match">
      <xsl:value-of select="replace(., '\{\$noclosebracket\}', '([^\\[]*)?')"/>
   </xsl:template>
   <xsl:template match="text" mode="write-match">
      <xsl:text>(.*?)</xsl:text>
   </xsl:template>
   <xsl:template match="insert/type | insert/id-ref" mode="write-match">
      <xsl:text>(\i\c*?)</xsl:text>
   </xsl:template>
   <xsl:template match="text[@not]" mode="write-match">
      <xsl:text expand-text="true">([^{ @not }]*?)</xsl:text>
   </xsl:template>
   <xsl:template match="*" mode="write-replace">
        <!-- we can write an open/close pair even for an empty element b/c
             it will be parsed and serialized -->
      <xsl:text>&lt;</xsl:text>
      <xsl:value-of select="local-name()"/>
      <!-- forcing the namespace! -->
      <xsl:text> xmlns="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"</xsl:text>
      <!-- coercing the order to ensure correct formation of regegex       -->
      <xsl:apply-templates mode="#current" select="@*"/>
      <xsl:text>&gt;</xsl:text>
      <xsl:apply-templates mode="#current" select="*"/>
      <xsl:text>&lt;/</xsl:text>
      <xsl:value-of select="local-name()"/>
      <xsl:text>&gt;</xsl:text>
   </xsl:template>
   <xsl:template match="text" mode="write-replace">
      <xsl:text>$1</xsl:text>
   </xsl:template>
   <xsl:template match="insert" mode="write-replace">
        <!-- we can write an open/close pair even for an empty element b/c
             it will be parsed and serialized -->
      <xsl:text>&lt;insert xmlns="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"</xsl:text>
      <!-- coercing the order to ensure correct formation of regegex       -->
      <xsl:apply-templates mode="#current" select="*"/>
      <xsl:text>/&gt;</xsl:text>
   </xsl:template>
   <xsl:template match="insert/type" mode="write-replace">
      <xsl:text> type='$1'</xsl:text>
   </xsl:template>
   <xsl:template match="insert/id-ref" mode="write-replace">
      <xsl:text> id-ref='$2'</xsl:text>
   </xsl:template>
   <xsl:template match="a/@href" mode="write-replace">
      <xsl:text> href='$2'</xsl:text>
      <!--<xsl:value-of select="replace(.,'\{\$insert\}','\$2')"/>-->
   </xsl:template>
   <xsl:template match="img/@alt" mode="write-replace">
      <xsl:text> alt='$1'</xsl:text>
      <!--<xsl:value-of select="replace(.,'\{\$insert\}','\$2')"/>-->
   </xsl:template>
   <xsl:template match="img/@src" mode="write-replace">
      <xsl:text> src='$2'</xsl:text>
      <!--<xsl:value-of select="replace(.,'\{\$insert\}','\$2')"/>-->
   </xsl:template>
   <xsl:variable name="line-example" xml:space="preserve"> { insertion } </xsl:variable>
   <!-- JSON to XML conversion: Supermodel serialization as XML -->
   <xsl:strip-space xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                     elements="s:*"/>
   <xsl:preserve-space xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                        elements="s:flag s:value"/>
   <xsl:mode xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
              name="write-xml"/>
   <xsl:template xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  match="s:*[exists(@gi)]"
                  mode="write-xml">
      <xsl:element name="{@gi}" namespace="http://csrc.nist.gov/ns/oscal/1.0">
            <!-- putting flags first in case of disarranged inputs -->
         <xsl:apply-templates select="s:flag, (* except s:flag)" mode="write-xml"/>
      </xsl:element>
   </xsl:template>
   <xsl:template xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  match="s:value[@as-type=('markup-line','markup-multiline')]"
                  mode="write-xml">
      <xsl:apply-templates mode="cast-prose"/>
   </xsl:template>
   <xsl:template xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  match="p | ul | ol | pre | h1 | h2 | h3 | h4 | h5 | h6 | table"
                  xpath-default-namespace="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel">
      <xsl:apply-templates select="." mode="cast-prose"/>
   </xsl:template>
   <xsl:template xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  priority="2"
                  match="s:flag"
                  mode="write-xml">
      <xsl:attribute name="{@gi}">
         <xsl:value-of select="."/>
      </xsl:attribute>
   </xsl:template>
   <xsl:template xmlns:s="http://csrc.nist.gov/ns/oscal/metaschema/1.0/supermodel"
                  match="*"
                  mode="cast-prose">
      <xsl:element name="{local-name()}" namespace="http://csrc.nist.gov/ns/oscal/1.0">
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:element>
   </xsl:template>
</xsl:stylesheet>
