import Excel from "exceljs";
import * as Target from "./GqlHandler.mjs";
import * as Expander from "./Utilities.mjs";

let argHost = process.argv.pop();

if (process.argv.length < 2 && argHost.slice(0,3) !== "http") {
    argHost = null;
}

// The default target is localhost to match the dev environment
const targetHost = argHost? argHost : "http://localhost:8080/api/";

const forceClean = process.env.CLEANUP || 1;

await Target.cleanup_all(targetHost, forceClean);

const parentdir = "data/sdgs";

const files = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16];

const matchTerms = await Promise.all(files.map(loadOneFile));

const fresults = await Promise.all(matchTerms.map(matcher => Target.injectData(targetHost, {matcher})));

console.log(JSON.stringify(fresults, null, "  "));

/* ************** SUPPORT FUNCTIONS ************************* */

async function loadWorkbook(sdgid) {
    const workbook = new Excel.Workbook();

    await workbook.xlsx.readFile(`${parentdir}/${sdgid}.xlsx`);
   
    return workbook.getWorksheet(sdgid);    
}

function loadHeadings(worksheet) {
    const headings = [];

    worksheet.getRow(1).eachCell((cell) => headings.push({ 
        lang: cell.value.slice(-2),
        key: cell.value.slice(0, -3)
    }));

    return headings;
}

async function loadOneFile(id) {
    const sdg = `SDG${id}`;
    const ws = await loadWorkbook(sdg);
    const constructs = [];

    if (ws) {
        const headings = loadHeadings(ws);

        ws.eachRow((row,rid) => {
            if (rid === 1) {
                return;
            }

            const obj = {
                id: `${sdg.toLowerCase()}_c${rid}`
            };

            row.eachCell((cell, cid) => {
                if (!cell.value.length) {
                    return;
                }

                cid -= 1;

                if (!(headings[cid].lang in obj)) {
                    obj[headings[cid].lang] = {
                        construct: `${obj.id}_${headings[cid].lang}`,
                        language: headings[cid].lang,
                        sdg: {
                            id: `sdg_${id}`
                        }
                    };
                }

                obj[headings[cid].lang][headings[cid].key] = cell.value.replaceAll("*", " ").trim();
            });
        
            ["en", "de", "fr", "it"].forEach(l => {
                if (l in obj) {
                    constructs.push(obj[l]);
                }
            });
        });
    } 

    return Expander.expand(constructs);
}
