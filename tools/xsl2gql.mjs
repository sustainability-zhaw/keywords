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

const matchTerms = await Promise.all(files.map(Expander.loadOneFile));

const fresults = await Promise.all(matchTerms.filter(m => m.length > 0).map(matcher => Target.injectData(targetHost, {matcher})));

console.log(JSON.stringify(fresults, null, "  "));

/* ************** SUPPORT FUNCTIONS ************************* */
