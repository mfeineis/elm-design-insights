const fs = require("fs");
const path = require("path");

const git = require("nodegit");
const {
    compose,
    equals,
    filter,
    forEach,
    map,
    pipe,
    prop,
    sortBy,
    T,
    tap,
    toLower,
} = require("ramda");

const { createTimestamp, rimraf } = require("./utils");

const repoUrls = [
    `https://github.com/avh4/elm-format`,
    `https://github.com/avh4/elm-upgrade`,
    `https://github.com/elm-community/linear-algebra`,
    `https://github.com/elm-community/webgl`,
    `https://github.com/elm-explorations/markdown`,
    `https://github.com/elm-explorations/elm-test`,
    `https://github.com/elm/browser`,
    `https://github.com/elm/bytes`,
    `https://github.com/elm/core`,
    `https://github.com/elm/dom`,
    `https://github.com/elm/compiler`,
    //`https://github.com/elm/elm-make`,
    //`https://github.com/elm/elm-platform`,
    `https://github.com/elm/error-message-catalog`,
    `https://github.com/elm/html`,
    `https://github.com/elm/http`,
    `https://github.com/elm/json`,
    //`https://github.com/elm/kernel`, // Not public but referenced in elm-lang/elm-compiler
    `https://github.com/elm/parser`,
    `https://github.com/elm/projects`,
    `https://github.com/elm/project-metadata-utils`,
    `https://github.com/elm/random`,
    `https://github.com/elm/regex`,
    `https://github.com/elm/time`,
    `https://github.com/elm/url`,
    //`https://github.com/elm/virtual-css`, // On hold, no longer referenced in elm-lang/elm-compiler
    `https://github.com/elm/virtual-dom`,
    `https://github.com/elm/websocket`,
    `https://github.com/elm/window`,
    `https://github.com/elm-tools/parser`,
];

const timestamp = createTimestamp(new Date());
const reposDir = path.resolve(__dirname, "../repos");
const dist = path.resolve(__dirname, "../dist");

const debugOutputFilePath = path.join(dist, `result-${timestamp}-readable.json`);
const latestOutputFilePath = path.join(dist, `result-latest.json`);
const outputFilePath = path.join(dist, `result-${timestamp}.json`);

if (fs.existsSync(dist)) {
    console.log(`Deleting ${dist}...`);
    rimraf(dist);
}

console.log(`Creating ${dist}...`);
fs.mkdirSync(dist);

console.log("checking out into: ", reposDir);

const release_0_12 = new Date("2014-05-01T00:00:00Z").getTime();
const release_0_13 = new Date("2014-09-21T00:00:00Z").getTime();
const release_0_14 = new Date("2014-12-09T00:00:00Z").getTime();
const release_0_15 = new Date("2015-04-20T00:00:00Z").getTime();
const release_0_16 = new Date("2015-11-22T00:00:00Z").getTime();
const release_0_17 = new Date("2016-05-06T00:00:00Z").getTime();
const release_0_18 = new Date("2016-11-11T00:00:00Z").getTime();
const alpha_0_19 = new Date("2018-05-10T00:00:00Z").getTime();
const release_0_19 = new Date("2018-08-21T00:00:00Z").getTime();

const march2018 = new Date("2018-03-01T00:00:00Z").getTime();

const isCommitInRange = min => max => commit => {
    const date = new Date(commit.date()).getTime();
    return date >= min && date < max;
};

const isAncient = isCommitInRange(0)(release_0_12);
const elm_0_13_design = isCommitInRange(release_0_12)(release_0_13);
const elm_0_14_design = isCommitInRange(release_0_13)(release_0_14);
const elm_0_15_design = isCommitInRange(release_0_14)(release_0_15);
const elm_0_16_design = isCommitInRange(release_0_15)(release_0_16);
const elm_0_17_design = isCommitInRange(release_0_16)(release_0_17);
const elm_0_18_design = isCommitInRange(release_0_17)(release_0_18);
const elm_0_19_design = isCommitInRange(release_0_18)(alpha_0_19);
const elm_0_19_public_alpha = isCommitInRange(alpha_0_19)(release_0_19);
const elm_0_20_design = isCommitInRange(release_0_19)(Date.now());

const getAllCommits = T;

const isPivotalAuthor = author => (
    equals("Evan Czaplicki", author) || equals("evancz", author)
);
const isPivotalEmail = email => (
    equals("evancz@users.noreply.github.com", email)  || equals("info@elm-lang.org", email)
);
const byPivotalAuthor = commit => (
    isPivotalAuthor(commit.author().name()) || isPivotalEmail(commit.author().email())
);
const isMergeCommit = commit => /merge pull request/gi.test(commit.summary());

const mightBeInteresting = commit => !!(
    /init(ial)?\s+commit/gi.test(commit.summary()) ||
    (byPivotalAuthor(commit) && commit.body() && !isMergeCommit(commit)) ||
    new Date(commit.date()).getTime() >= march2018
);

const dateToPosix = date => date.getTime() / 1000 | 0;

const extractCommitInfo = ({ repoName, repoUrl }) => commit => ({
    authorEmail: commit.author().email(),
    authorName: commit.author().name(),
    authorInfo: commit.author().toString(),
    body: commit.body(),
    date: dateToPosix(commit.date()),
    meta: {
        byPivotalAuthor: byPivotalAuthor(commit),
        elm_0_13_design: elm_0_13_design(commit),
        elm_0_14_design: elm_0_14_design(commit),
        elm_0_15_design: elm_0_15_design(commit),
        elm_0_16_design: elm_0_16_design(commit),
        elm_0_17_design: elm_0_17_design(commit),
        elm_0_18_design: elm_0_18_design(commit),
        elm_0_19_design: elm_0_19_design(commit),
        elm_0_19_public_alpha: elm_0_19_public_alpha(commit),
        elm_0_20_design: elm_0_20_design(commit),
        isAncient: isAncient(commit),
        mightBeInteresting: mightBeInteresting(commit),
    },
    repoName,
    repoUrl,
    sha: commit.sha(),
    summary: commit.summary(),
});

const analyzeRepo = info => repo => {
    console.log(`-> Analyzing ${info.repoName}...`);
    const walker = git.Revwalk.create(repo);

    // Sort all commits to the repo in time from the past until now
    walker.sorting(git.Revwalk.SORT.TIME, git.Revwalk.SORT.REVERSE);
    walker.pushGlob('refs/heads/*');

    const walk = extractCommitInfo(info);
    return walker.getCommitsUntil(getAllCommits).then(map(walk));
};

const walkRepo = put => url => {
    let repoPath = null;
    let repoName = null;
    url.replace(/([^/]+)\/([^/]+)$/, (match, org, name) => {
        repoName = `${org}/${name}`;
        repoPath = path.join(reposDir, `${org}__${name}`);
    });

    const info = {
        repoName,
        repoPath,
        repoUrl: url,
    };

    let repository = null;

    if (fs.existsSync(repoPath)) {
        rimraf(repoPath);
    }

    console.log();
    return git.Clone(url, repoPath)
        .then(() => git.Repository.open(repoPath))
        .then(repo => (console.log(`\nCloning ${repoName}...`), analyzeRepo(info)(repo)))
        .then(commits => commits.forEach(put))
        .catch(console.error);
};

const allCommits = [];
const walk = walkRepo(commit => allCommits.push(commit));

const compact = x => JSON.stringify(x);
const pretty = x => JSON.stringify(x, null, "  ");

Promise.all(map(walk, repoUrls)).then(() => {
    console.log("\n# allCommits\n", allCommits.length);

    pipe(
        sortBy(prop("date")),
        tap(result => fs.writeFileSync(debugOutputFilePath, pretty(result), "utf-8")),
        tap(result => fs.writeFileSync(outputFilePath, compact(result), "utf-8")),
        tap(result => fs.writeFileSync(latestOutputFilePath, compact(result), "utf-8"))
    )(allCommits);
});
