
export function expand(construct) {
    return expandConstruct(construct, "required_context").map(o => expandConstruct(o, "forbidden_context")).flat();
}

function expandConstruct(obj, type) {
    if (!obj) {
        return [];
    }

    if (Array.isArray(obj)) {
        return obj.map((o)=> expandConstruct(o, type)).flat();
    }

    if (!(type in obj)) {
        return [obj];
    }

    const result = [];
    
    obj[type]
        .split(",")
        .map(t => t.trim())
        .reduce((res, t, i) => {
            const tmpObj = Object.assign({}, obj);
            
            i += 1;

            tmpObj.construct = `${tmpObj.construct}_${i}`
            tmpObj[type] = t;
            res.push(tmpObj);
            return res;
        }, result)

    return result;
}
