const express = require("express");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const app = express();

app.use(express.json());

mongoose.connect(
  "mongodb+srv://madmin:<password>@clustername.mongodb.net/<dbname>?retryWrites=true&w=majority",
  {
    useNewUrlParser: true,
    useFindAndModify: false,
    useUnifiedTopology: true,
  }
);

// 8x8HQ4WichXXu2S
// 4WAd@!3NGJ@kKji
const URI =
  "mongodb+srv://jjzfive-harkness:4WAd%40%213NGJ%40kKji@cluster0.m1my3.mongodb.net/test?retryWrites=true&w=majority";
dotenv.config();

app.get("/", async (req, res) => {
  res.send("hi you");
});

app.listen(3000);
