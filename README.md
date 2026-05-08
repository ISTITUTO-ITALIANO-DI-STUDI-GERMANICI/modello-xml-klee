# DIScEPT Sync

This is a package that connects DIScEPT environment to eXist-db, giving some tools that might be useful for alignment.

## Main features
- Storing savings from DIScEPT
- Converting an XML file from Euporia to XML TEI

## Other current features
- Backup and restore projects if another version of Sync would be installed

## How to install
- Download .xar file in repository
- Install it on your exist-db package manager

## Content of the package
`discept-sync
│   collection.xconf    --> Configuration of aligments collection: it registers versioning-trigger.xqm executed every time a file is created or edited
│   controller.xql      --> HTTP router of the eXist application. All REST requests are forwarded to rest-bridge.xql.
│   discept-sync.xar    --> The package itself ready to be installed
│   expath-pkg.xml      --> EXPath package metadata
│   index.html          --> Web interface
│   post-install.xq     --> Script executed after package installation (installs collection.xconf and give read and write permissions to the package on eXist-db)
│   pre-install.xq      --> Script executed before package installation (all folders are created in eXist-db)
│   repo.xml            --> Repository metadata
└───src
    ├───api
    │       alignments.xql            --> Internal API management, working with internal endpoints, manages also CRUD requests internal on eXist-db
    │       ping.xql                  --> Check the health of the connection (it's related to Sync feature, it basically says if there's connection or not)
    │       rest-bridge.xql           --> Emulates the eXist-db REST interface that exposes natively. For internal UI it's used alignements.xql
    │       transform.xql             --> Endpoint that accepts an uploaded XML file to be converted to XML/TEI via defined XSLT
    │       versioning-trigger.xqm    --> Every time a document is created or updated, it saves automatically a copy in versions folder //TODO: save versions from DIScEPT and not just from Sync
    ├───app                --> Client side files
    │   ├───script
    │   │       script.js  --> Functions related to the application itself
    │   └───style
    │           style.css  --> Style of the application
    ├───dsl
    │       fetch.xql      --> Future file that manages sycing from DIScEPT (the folder name is temporary)
    ├───modules
    │       transform.xqm  -->  Uploads parsedToTEI.xsl in xslt folder and applies the trasformation to the uploaded XML via the internal Saxon XSL compiler
    └───xslt
            parsedToTEI.xsl --> The XSL file which converts an Euporia XML in XML/TEI`
            
## Future features
- Syncing from DIScEPT/Euporia/eScriptorium
- Managing different projects
- Managing different versions of the same project for restoring the previous work (such as for errors)
- Night mode

## Credits
Made with ❤️ by Calogero Giudice - Istituto Italiano di Studi Germanici
