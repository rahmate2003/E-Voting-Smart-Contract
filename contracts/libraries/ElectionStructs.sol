// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

library ElectionStructs {
    struct Candidate {
        bytes32 id;
        string Cname;
        uint CNIM;
        string Cjurusan;
        string Cprodi;
        string Wname;
        uint WNIM;
        string Wjurusan;
        string Wprodi;
        string photoPath;
        uint voteCount;
    }

    struct User {
        string name;
        uint NIM;
        string jurusan;
        string prodi;
        address add;
        uint voteTimestamp;
    }
}
