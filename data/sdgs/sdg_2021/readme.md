# 16-SDG Translation Revision #

There are 16 files in this folder, each relating to an sdg. The structure of the individual files is as follows:

**4 Sheets, english= en, german = de, french = fr, italian = it**

#### Sheet english: ####
-   Cell A1, sdg titel, e.g. "SDG4: Quality Education"
-   Cell A2, "original"
-   Cell A3, "keyword"
-   Cell A4: , english keywords

-   Cell B2, "context"
-   Cell B3, "extra"
-   Cell B4: content/topic related remarks

#### In addition to the two columns on the en sheet, there are the three additional columns C, D, E on the de, fr, it sheets ####

- Cell C2, "deepl" - translation engine
- Cell C3, "Stichwort", "mot-clé", "parola chiave"
- Cell C4: , deepl de, fr, it translation. Source: Cell A3  

- Cell D2, "google" - translation engine
- Cell D3, "Stichwort", "mot-clé", "parola chiave"
- Cell D4: , google de, fr, it translation. Source: Cell A3 

- Cell E2: "final translation". **This column is to be filled in with the best translation that fits the overall theme of the SDG in question (cell A1) and the context (B)**.  

### Keywords translation with regard to text mining ###
The original keywords (cell A) were defined by experts and must be taken as they are. However, for our text analysis project, not all keywords/terms can be used as is. Single words can simply be used directly or in a stemmed form. Terms with two or more words need to be carefully analyzed. Let's take an example: *award in education and training*. The task of text mining is to find all documents that contribute something to the content of the term. A first naive text mining approach is to search for *award*, *education* and *training* as single, unrelated words. The results will contain many **false positives**, i.e., documents that contain the individual words but in a different context. To bring the result of the naive model closer to the real space, prepositions are our supporters, as they put the individual words in a first and direct context. "Awarded in ..." makes it clear that it is a subsequent condition of the *prior* condition "education and training".  

Since the actual task is to translate the given English expressions into German, French and Italian, **the main focus should be on a translation that allows us to create queries**. 
Returning to our example, a text-mining operation first searches for all documents containing the *prior" keywords *education* **or** *education*. The resulting documents are queried again for the *posterior* keyword(s) *award*.
There are many text mining methods that further optimize the described approach. 
Once the keywords are carefully translated, our next step is to programmatically create queries as described in the previous example. 

## Translation task ##
This section is primarily for the professionals translating the 16 SDGs.
We are looking for keyword lists in all languages, where each keyword is the best possible contextual term. As in the example above, a combination of words held together by prepositions might better express the original meaning of the keyword than a directly translated single word, which is hard to find in the corpus because it is not commonly used in the natural language.
