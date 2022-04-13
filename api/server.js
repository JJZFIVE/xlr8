const express = require("express");
const dotenv = require("dotenv");
const mongoose = require("mongoose");
const carModel = require("./models/carmodels");
const app = express();

app.use(express.json());

// Mongodb testing: URI saved in the .env
// database admin username: testaccount
// password123ab

dotenv.config();
const URI = process.env.DB_URI;

mongoose.connect(URI, {
  useNewUrlParser: true,
  useFindAndModify: false,
  useUnifiedTopology: true,
});

// Main dynamic URI called by Chainlink
app.get("/:wheel/:engine/:build/:wrapping", async (req, res) => {
  const car = await carModel.find({
    wheel: req.params.wheel,
    engine: req.params.engine,
    build: req.params.build,
    wrapping: req.params.wrapping,
  });

  let returnURI;
  try {
    returnURI = { tokenURI: car[0].fullcarmetadata };
  } catch (error) {
    returnURI = { tokenURI: "Invalid parameters" };
    console.log(error);
  }

  try {
    res.status(200).send(returnURI);
  } catch (error) {
    res.status(500).send(error);
  }
});

// For testing adding new data
app.get("/add/:wheel/:engine/:build/:wrapping", async (req, res) => {
  const newCar = new carModel({
    wheel: req.params.wheel,
    engine: req.params.engine,
    build: req.params.build,
    wrapping: req.params.wrapping,
    fullcarimage: "ipfs-full-car-image",
    fullcarvox: "ipfs-full-car-vox",
    fullcarmetadata: "ipfs-full-car-metadata",
  });

  newCar.save((err, user) => {
    if (err) {
      res.json({
        success: false,
        message: "There was a problem with saving a new car",
      });
    }
  });

  const cars = await carModel.find({});

  try {
    res.status(200).send(cars);
  } catch (error) {
    res.status(500).send(error);
  }
});

// For testing. Take out for production
app.get("/all-cars", async (req, res) => {
  const cars = await carModel.find({});

  try {
    res.status(200).send(cars);
  } catch (error) {
    res.status(500).send(error);
  }
});

// Dear God also for testing only. Remove for production
app.get("/delete-all", async (req, res) => {
  const del = await carModel.remove({}, (callback) => {
    console.log(callback);
  });
  res.send(del);
});

app.listen(3000);
