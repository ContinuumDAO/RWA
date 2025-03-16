const fs = require("fs")
const dappID44 = JSON.parse(fs.readFileSync("./dappID-44.json"))
const dappID45 = JSON.parse(fs.readFileSync("./dappID-45.json"))
const dappID46 = JSON.parse(fs.readFileSync("./dappID-46.json"))
const dappID47 = JSON.parse(fs.readFileSync("./dappID-47.json"))
const dappID48 = JSON.parse(fs.readFileSync("./dappID-48.json"))
const dappID58 = JSON.parse(fs.readFileSync("./dappID-58.json"))


console.log(`44, length ${dappID44.data.length}`)
console.dir(dappID44.data.map(i => i.contract_addr), {"maxArrayLength": null})

console.log(`\n45, length ${dappID45.data.length}`)
console.dir(dappID45.data.map(i => i.contract_addr), {"maxArrayLength": null})

console.log(`\n46, length ${dappID46.data.length}`)
console.dir(dappID46.data.map(i => i.contract_addr), {"maxArrayLength": null})

console.log(`\n47, length ${dappID47.data.length}`)
console.dir(dappID47.data.map(i => i.contract_addr), {"maxArrayLength": null})

console.log(`\n48, length ${dappID48.data.length}`)
console.dir(dappID48.data.map(i => i.contract_addr), {"maxArrayLength": null})

console.log(`\n58, length ${dappID58.data.length}`)
console.dir(dappID58.data.map(i => i.contract_addr), {"maxArrayLength": null})

