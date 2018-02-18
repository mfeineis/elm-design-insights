const fs = require("fs");
const path = require("path");

const rimraf = dir_path => {
    if (fs.existsSync(dir_path)) {
        fs.readdirSync(dir_path).forEach(entry => {
            var entry_path = path.join(dir_path, entry);
            if (fs.lstatSync(entry_path).isDirectory()) {
                rimraf(entry_path);
            } else {
                fs.unlinkSync(entry_path);
            }
        });
        fs.rmdirSync(dir_path);
    }
};

const createTimestamp = date => {
    let yyyy = date.getFullYear();

    let MM = date.getMonth() + 1;
    if (MM < 10) {
        MM = "0" + MM;
    }

    let dd = date.getDate();
    if (dd < 10) {
        dd = "0" + dd;
    }

    let HH = date.getHours();
    if (HH < 10) {
        HH = "0" + HH;
    }

    let mm = date.getMinutes();
    if (mm < 10) {
        mm = "0" + mm;
    }

    let ss = date.getSeconds();
    if (ss < 10) {
        ss = "0" + ss;
    }

    return `${yyyy}-${MM}-${dd}_${HH}${mm}${ss}`;
};

module.exports = {
    createTimestamp,
    rimraf,
};
