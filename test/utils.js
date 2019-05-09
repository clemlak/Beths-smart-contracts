function toSolidityTimestamp(timestamp) {
  return Math.round(timestamp / 1000);
}

const Status = {
  Open: 0,
  OnGoing: 1,
  Disputed: 2,
  Won: 3,
  Lost: 4,
};

const ProposedOutcome = {
  Won: 1,
  Lost: 2,
};

module.exports = {
  toSolidityTimestamp,
  Status,
  ProposedOutcome,
};
