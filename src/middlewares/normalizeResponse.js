export const normalizeIdMiddleware = (req, res, next) => {
    const originalJson = res.json;

    res.json = function (data) {
        const normalized = normalizeData(data);
        return originalJson.call(this, normalized);
    };

    next();
}

const normalizeData = (data) => {

    if (data === null) return "";

    if (Array.isArray(data)) {
        return data.map(item => normalizeData(item));
    }

    if (data && typeof data === "object") {
        const newObj = {};

        for (const key in data) {
            if (!Object.hasOwn(data, key)) continue;

            if (key === "_id") {
                newObj.id = data._id?.toString() || "";
                continue;
            }

            newObj[key] = normalizeData(data[key]);
        }

        return newObj;
    }

    return data;
}
