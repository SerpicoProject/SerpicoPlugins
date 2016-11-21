# Overview

This plug-in generates a branded word document from BurpSuite results XML import.

# Command Line

The plugin can be run from the command line in the Serpico directory.

```
cd plugins/BurpAppendix
ruby ba_cli.rb [XML_DATA] [TEMPLATE_DOCX]
```

e.g.
```
ruby ba_cli.rb burp_results.xml branded.docx
```