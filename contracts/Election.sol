// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {ElectionStructs} from "./libraries/ElectionStructs.sol";
import {ElectionEvents} from "./libraries/ElectionEvents.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract Election is ReentrancyGuard {
    address public admin;
    bool public electionStarted;
    bool public electionEnded;
    uint public candidatesCount;
    uint public usersCount;
    uint public totalVotes;

    bytes32 public whitelistMerkleRoot;

    mapping(uint => ElectionStructs.Candidate) public candidates;
    mapping(uint => ElectionStructs.User) public users;
    mapping(address => uint) public userByAddress;
    mapping(uint => uint) public userByNIM;
    mapping(uint => uint) public candidatesByNIM;
    mapping(uint => uint) public candidatesByWNIM;
    mapping(address => bool) public hasVoted;
    mapping(bytes32 => uint) public candidateIndexById;

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Hanya Admin yang bisa Melakukan Aksi Ini"
        );
        _;
    }

    modifier notAdmin() {
        require(msg.sender != admin, "Admin Tidak Dapat Melakukan Aksi Ini");
        _;
    }

    modifier electionNotOngoing() {
        require(
            !electionEnded,
            "Pemilihan Telah Selesai. Tidak bisa melakukan aksi ini"
        );
        require(
            !electionStarted,
            "Pemilihan Sedang Berjalan. Tidak bisa melakukan aksi ini"
        );
        _;
    }

    modifier electionOngoing() {
        require(
            electionStarted,
            "Pemilihan Belum Dimulai. Tidak bisa melakukan aksi ini"
        );
        require(
            !electionEnded,
            "Pemilihan Telah Selesai. Tidak bisa melakukan aksi ini"
        );
        _;
    }

    // CONSTRUCTOR
    constructor() {
        admin = msg.sender;
        electionStarted = false;
        electionEnded = false;
    }
    // Set Merkle Root for whitelisting
    function setWhitelistMerkleRoot(
        bytes32 _merkleRoot
    ) public onlyAdmin electionNotOngoing nonReentrant {
        require(
            whitelistMerkleRoot == bytes32(0),
            "Whitelist Pemilih telah diatur dan tidak dapat diubah"
        );

        whitelistMerkleRoot = _merkleRoot;

        emit ElectionEvents.setWhitelistNIM(_merkleRoot);
    }
    function addCandidate(
        string memory _Cname,
        uint _CNIM,
        string memory _Cjurusan,
        string memory _Cprodi,
        string memory _Wname,
        uint _WNIM,
        string memory _Wjurusan,
        string memory _Wprodi,
        string memory _photoPath
    ) public onlyAdmin electionNotOngoing nonReentrant {
        require(
            bytes(_Cname).length > 0,
            "Nama Calon Presiden Kandidat di butuhkan."
        );
        require(
            bytes(_Wname).length > 0,
            "Nama Calon Wakil Presiden Kandidat di butuhkan."
        );
        require(_CNIM > 0, "NIM Calon Presiden Kandidat di butuhkan.");
        require(_WNIM > 0, "NIM Calon Wakil Presiden Kandidat di butuhkan.");
        require(
            bytes(_Wjurusan).length > 0,
            "Jurusan Calon Wakil di butuhkan."
        );
        require(
            bytes(_Wprodi).length > 0,
            "Prodi Calon Wakil Presiden di butuhkan."
        );
        require(
            _CNIM != _WNIM,
            "NIM calon Presiden dan NIM Wakil Tidak Bisa Sama."
        );
        require(candidatesByNIM[_CNIM] == 0, "NIM Calon Presiden Telah Ada.");
        require(
            candidatesByWNIM[_WNIM] == 0,
            "NIM Wakil Calon Presiden Telah ada."
        );
        require(
            candidatesByWNIM[_CNIM] == 0,
            "NIM Calon Presiden telah ada untuk Calon Wakil Presiden."
        );
        require(
            candidatesByNIM[_WNIM] == 0,
            "NIM Wakil Calon Presiden telah ada untuk Calon Presiden."
        );

        candidatesCount++;
        bytes32 candidateId = keccak256(
            abi.encodePacked(_CNIM, _WNIM, msg.sender)
        );

        candidates[candidatesCount] = ElectionStructs.Candidate(
            candidateId,
            _Cname,
            _CNIM,
            _Cjurusan,
            _Cprodi,
            _Wname,
            _WNIM,
            _Wjurusan,
            _Wprodi,
            _photoPath,
            0
        );
        candidateIndexById[candidateId] = candidatesCount;
        candidatesByNIM[_CNIM] = candidatesCount;
        candidatesByWNIM[_WNIM] = candidatesCount;

        emit ElectionEvents.AddCandidate(candidateId, _CNIM, _WNIM, _photoPath);
    }

    function startElection() public onlyAdmin electionNotOngoing nonReentrant {
        require(
            candidatesCount > 0,
            "Tidak bisa memulai pemilihan tanpa kandidat"
        );
        require(
            whitelistMerkleRoot != bytes32(0),
            "Belum Menambahkan Whitelist"
        );
        electionStarted = true;
        electionEnded = false;
        emit ElectionEvents.ElectionStarted();
    }

    function endElection() public onlyAdmin electionOngoing nonReentrant {
        electionEnded = true;
        emit ElectionEvents.ElectionEnded();
    }

    function addUser(
        string memory _name,
        uint _NIM,
        string memory _jurusan,
        string memory _prodi,
        bytes32[] calldata _merkleProof
    ) public notAdmin electionOngoing nonReentrant {
        bytes32 leaf = keccak256(abi.encodePacked(_NIM));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "NIM Tidak Berada di Whitelist"
        );

        require(bytes(_name).length > 0, "Nama dibutuhkan");
        require(_NIM > 0, "NIM dibutuhkan");
        require(userByNIM[_NIM] == 0, "Pemilih dengan NIM ini telah ada");
        require(userByAddress[msg.sender] == 0, "Address telah terdaftar");
        usersCount++;
        users[usersCount] = ElectionStructs.User(
            _name,
            _NIM,
            _jurusan,
            _prodi,
            msg.sender,
            0
        );
        userByNIM[_NIM] = usersCount;
        userByAddress[msg.sender] = usersCount;
        emit ElectionEvents.AddUser(
            _NIM,
            _name,
            _jurusan,
            _prodi,
            msg.sender,
            0
        );
    }

    function vote(
        bytes32 _candidateId
    ) public notAdmin electionOngoing nonReentrant {
        require(!hasVoted[msg.sender], "Pemilih telah Melakukan Voting");
        uint userIndex = userByAddress[msg.sender];
        require(userIndex != 0, "Pemilih Belum Mendaftar atau Register");
        ElectionStructs.User storage user = users[userIndex];
        require(
            user.add == msg.sender,
            "Ketidakcocokan address untuk pengguna terdaftar"
        );
        uint candidateIndex = candidateIndexById[_candidateId];
        require(candidateIndex != 0, "Kandidat Tidak Ditemukan");
        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;
        totalVotes++;
        user.voteTimestamp = block.timestamp;

        emit ElectionEvents.CastVote(_candidateId, msg.sender, block.timestamp);
    }
}
