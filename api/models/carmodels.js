const mongoose = require("mongoose");

const MAX_COMPONENT_SUPPLY = 6969; // Change this when we publish smart contracts

const CarSchema = new mongoose.Schema({
  wheel: {
    type: Number,
    required: true,
    trim: true,
    validate(value) {
      if (value > MAX_COMPONENT_SUPPLY || value < 0)
        throw new Error("Invalid wheel value");
    },
  },
  engine: {
    type: Number,
    required: true,
    trim: true,
    validate(value) {
      if (value > MAX_COMPONENT_SUPPLY || value < 0)
        throw new Error("Invalid engine value");
    },
  },
  build: {
    type: Number,
    required: true,
    trim: true,
    validate(value) {
      if (value > MAX_COMPONENT_SUPPLY || value < 0)
        throw new Error("Invalid build value");
    },
  },
  wrapping: {
    type: Number,
    required: true,
    trim: true,
    validate(value) {
      if (value > MAX_COMPONENT_SUPPLY || value < 0)
        throw new Error("Invalid wrapping value");
    },
  },
  fullcarimage: {
    type: String,
    default: "",
    // required: true, uncomment this for real thing
    trim: true,
  },
  fullcarvox: {
    type: String,
    default: "",
    // required: true, uncomment this for real thing
    trim: true,
  },
  fullcarmetadata: {
    type: String,
    default: "",
    // required: true, uncomment this for real thing
    trim: true,
  },
});

const Car = mongoose.model("Car", CarSchema);

module.exports = Car;
