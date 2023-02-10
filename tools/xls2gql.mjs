import * as Target from "./GqlHandler.mjs";
import * as Expander from "./Utilities.mjs";

let argHost = process.argv.pop();

if (process.argv.length < 2 && argHost.slice(0,3) !== "http") {
    argHost = null;
}

// The default target is localhost to match the dev environment
const targetHost = argHost? argHost : "http://localhost:8080/api/";

const forceClean = process.env.CLEANUP || 1;

await Target.cleanup_all(targetHost, true);
// process.exit();

const parentdir = "data/sdgs";

const files = Array(16).fill().map((_,i) => i + 1);

const matchTerms = await Promise.all(files.map(Expander.loadOneFile(parentdir)));

const fresults = await Promise.all(matchTerms.filter(m => m.length > 0).map(matcher => Target.injectData(targetHost, {matcher})));
