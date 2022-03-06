const express = require("express");
const app = express();

app.get("/", (req, res) => {
  console.log("Test");

  res.send("hi");
});

app.listen(3000);
