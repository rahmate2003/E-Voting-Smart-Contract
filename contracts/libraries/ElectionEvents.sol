// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library ElectionEvents {
    event AddCandidate(
        bytes32 indexed candidateId,
        uint PNIM,
        uint WNIM,
        string photoPath
    );
    event setWhitelistNIM(bytes32 merkleRoot);

    event ElectionStarted();

    event AddUser(
        uint NIM,
        string name,
        string jurusan,
        string prodi,
        address userAddress,
        uint voteTimestamp
    );

    event CastVote(
        bytes32 indexed candidateId,
        address userAddress,
        uint userVoteTimestamp
    );

    event ElectionEnded();
}
