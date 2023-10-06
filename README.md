## NounsGovEscrow (aka BOB)

This smart contract allows for the escrowing of Nouns distributed to future 
governors.

It allows for a configurable vote threshold and maturity time before the Noun can
be claimed by the receiver. The Noun can be clawed back any time if the vote
threshold and maturity time is not reached.

ENS reverse records can be configured by the receiver by calling `setENS`