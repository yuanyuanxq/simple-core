// Generates Hasher artifact at compile-time using Truffle's external compiler
// mechanism
const path = require("path");
const fs = require("fs");
// const genContract = require("circomlibjs/src/mimcsponge_gencontract.js");
const circomlibjs = require("circomlibjs");

const outputPath = path.join(__dirname, "..", "build/contracts/Hasher.json");
const mkdirPath = path.join(__dirname, "../build/contracts");

function main() {
  // console.log(circomlibjs)

  const contract = {
    contractName: "Hasher",
    abi: circomlibjs.mimcSpongecontract.abi,
    bytecode: circomlibjs.mimcSpongecontract.createCode("mimcsponge", 220),
  };

  if (!fs.existsSync(outputPath)) {
    fs.mkdirSync(mkdirPath, { recursive: true });
  }

  fs.writeFileSync(outputPath, JSON.stringify(contract));
  console.log(`success: ${outputPath}`);
}

main();
