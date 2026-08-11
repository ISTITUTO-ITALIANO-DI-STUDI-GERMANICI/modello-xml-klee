# TEI Model (draft)
The TEI-XML represents two levels of the text: a diplomatic transcription and a “pre-critical” edition.

## Diplomatic transcription
The text is contained within <sourceDoc>.

The minimal citation unit is <seg>.

The document is divided into pages using <pb>, each of which corresponds to the number of the facsimile (via the @facs attribute

Each page is divided into <zone> elements, which are further structured into <line> elements.

Titles of units or lessons are expressed through the @type attribute of <line> elements.

Elements such as <del>, <add>, and <subst> are present.

The <milestone> tag is used to indicate a graphic element (e.g., *) that usually marks the end of a section.

No critical notes or emendations are included.

## Critical
The text is contained within <text>.

The minimal citation unit is <w>.

<del> elements are not present.

<add> elements are incorporated directly into the text.

Titles are marked with <head> elements, and a corresponding <div> is created for each of them.

The <milestone> tag is used to indicate a graphic element (e.g., *) that usually marks the end of a section.

Critical notes (e.g., corrections or normalizations) are expressed using <choice>.
