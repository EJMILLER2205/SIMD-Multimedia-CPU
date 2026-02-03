#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cctype>

using namespace std;

// ------------------------------------------------------------
// Helper functions
// ------------------------------------------------------------

// Checks for whitespace characters we want to treat as separators
bool isSpaceChar(char c) {
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

// Trim leading/trailing spaces and tabs/newlines
string trim(const string& s) {
    int n = (int)s.size();
    int i = 0;
    while (i < n && isSpaceChar(s[i])) {
        i++;
    }
    if (i == n) {
        return "";
    }
    int j = n - 1;
    while (j >= 0 && isSpaceChar(s[j])) {
        j--;
    }
    return s.substr(i, j - i + 1);
}

// Strip comments starting with '#' or '//' anywhere on the line
string stripComments(const string& line) {
    size_t posHash = line.find('#');
    size_t posSlashSlash = line.find("//");

    size_t cutPos = string::npos;
    if (posHash != string::npos) {
        cutPos = posHash;
    }
    if (posSlashSlash != string::npos) {
        if (cutPos == string::npos || posSlashSlash < cutPos) {
            cutPos = posSlashSlash;
        }
    }

    if (cutPos == string::npos) {
        return line;
    }
    return line.substr(0, cutPos);
}

// Split a line into tokens by spaces, commas, and whitespace
vector<string> tokenize(const string& line) {
    vector<string> toks;
    string cur;
    for (size_t i = 0; i < line.size(); ++i) {
        char c = line[i];
        if (c == ',' || isSpaceChar(c)) {
            if (!cur.empty()) {
                toks.push_back(cur);
                cur.clear();
            }
        }
        else {
            cur.push_back(c);
        }
    }
    if (!cur.empty()) {
        toks.push_back(cur);
    }
    return toks;
}

// Convert string to int (supports decimal and 0x... hex)
int strToInt(const string& s) {
    int sign = 1;
    int idx = 0;
    int n = (int)s.size();
    if (n > 0 && s[0] == '-') {
        sign = -1;
        idx = 1;
    }

    // Hex literal: 0x.... or 0X....
    if (idx + 1 < n && s[idx] == '0' && (s[idx + 1] == 'x' || s[idx + 1] == 'X')) {
        idx += 2;
        int val = 0;
        for (; idx < n; ++idx) {
            char c = s[idx];
            int digit;
            if (c >= '0' && c <= '9') {
                digit = c - '0';
            }
            else if (c >= 'a' && c <= 'f') {
                digit = 10 + (c - 'a');
            }
            else if (c >= 'A' && c <= 'F') {
                digit = 10 + (c - 'A');
            }
            else {
                break;
            }
            val = (val << 4) | digit; // multiply by 16 + digit
        }
        return sign * val;
    }

    // Decimal (original behavior)
    int val = 0;
    for (; idx < n; ++idx) {
        char c = s[idx];
        if (c >= '0' && c <= '9') {
            val = val * 10 + (c - '0');
        }
        else {
            break;
        }
    }
    return sign * val;
}

// Make a string uppercase
string toUpperStr(string s) {
    for (size_t i = 0; i < s.size(); ++i) {
        s[i] = (char)toupper((unsigned char)s[i]);
    }
    return s;
}

// Parse register token: r0..r31 / R0..R31.
int parseReg(const string& tok) {
    if (tok.size() < 2) {
        return 0;
    }
    char c0 = tok[0];
    if (c0 != 'r' && c0 != 'R') {
        return 0;
    }
    string numPart = tok.substr(1);
    int idx = strToInt(numPart);
    if (idx < 0) {
        idx = 0;
    }
    if (idx > 31) {
        idx = 31;
    }
    return idx;
}

// Parse 16-bit immediate
int parseImm16(const string& tok) {
    int v = strToInt(tok);
    if (v < 0) {
        v &= 0xFFFF;
    }
    return v & 0xFFFF;
}

// Parse load index 0..7.
int parseLoadIndex(const string& tok) {
    int v = strToInt(tok);
    if (v < 0) v = 0;
    if (v > 7) v = 7;
    return v;
}

// ------------------------------------------------------------
// Opcode tables
// ------------------------------------------------------------

// R3 opcode
int opcodeR3(const string& mnUpper) {
    if (mnUpper == "NOP")    return 0x00; // ----0000
    if (mnUpper == "SHRHI")  return 0x01; // ----0001
    if (mnUpper == "AU")     return 0x02; // ----0010
    if (mnUpper == "CNT1H")  return 0x03; // ----0011
    if (mnUpper == "AHS")    return 0x04; // ----0100
    if (mnUpper == "OR")     return 0x05; // ----0101
    if (mnUpper == "BCW")    return 0x06; // ----0110
    if (mnUpper == "MAXWS")  return 0x07; // ----0111
    if (mnUpper == "MINWS")  return 0x08; // ----1000
    if (mnUpper == "MLHU")   return 0x09; // ----1001
    if (mnUpper == "MLHCU")  return 0x0A; // ----1010
    if (mnUpper == "AND")    return 0x0B; // ----1011
    if (mnUpper == "CLZW")   return 0x0C; // ----1100
    if (mnUpper == "ROTW")   return 0x0D; // ----1101
    if (mnUpper == "SFWU")   return 0x0E; // ----1110
    if (mnUpper == "SFHS")   return 0x0F; // ----1111
    return -1;
}

// R4 opcode
int opcodeR4(const string& mnUpper) {
    if (mnUpper == "MADDL")   return 0; // 000
    if (mnUpper == "MADDH")   return 1; // 001
    if (mnUpper == "MSUBL")   return 2; // 010
    if (mnUpper == "MSUBH")   return 3; // 011
    if (mnUpper == "MLADDL")  return 4; // 100
    if (mnUpper == "MLADDH")  return 5; // 101
    if (mnUpper == "MLSUBL")  return 6; // 110
    if (mnUpper == "MLSUBH")  return 7; // 111
    return -1;
}

// ------------------------------------------------------------
// Instruction encoders (25-bit words packed into uint32_t)
// ------------------------------------------------------------

// R3: bit24=1, bit23=1, [22..15]=opcode, [14..10]=rs2, [9..5]=rs1, [4..0]=rd
unsigned int encodeR3(unsigned int opc, unsigned int rd,
    unsigned int rs1, unsigned int rs2) {
    unsigned int inst = 0;
    inst |= (1u << 24);                 // bit 24 = 1
    inst |= (1u << 23);                 // bit 23 = 1
    inst |= (opc & 0xFFu) << 15;        // bits 22..15 opcode
    inst |= (rs2 & 0x1Fu) << 10;        // bits 14..10 rs2
    inst |= (rs1 & 0x1Fu) << 5;         // bits 9..5 rs1
    inst |= (rd & 0x1Fu);               // bits 4..0 rd
    return inst;
}

// R4: bit24=1, bit23=0, [22..20]=opcode, [19..15]=rs3, [14..10]=rs2, [9..5]=rs1, [4..0]=rd
unsigned int encodeR4(unsigned int opc4, unsigned int rd,
    unsigned int rs1, unsigned int rs2, unsigned int rs3) {
    unsigned int inst = 0;
    inst |= (1u << 24);                 // bit 24 = 1
    // bit 23 = 0 (by default)
    inst |= (opc4 & 0x7u) << 20;        // bits 22..20
    inst |= (rs3 & 0x1Fu) << 15;        // bits 19..15 rs3
    inst |= (rs2 & 0x1Fu) << 10;        // bits 14..10 rs2
    inst |= (rs1 & 0x1Fu) << 5;         // bits 9..5 rs1
    inst |= (rd & 0x1Fu);               // bits 4..0 rd
    return inst;
}

// LI: bit24=0, [23..21]=load index, [20..5]=imm16, [4..0]=rd
unsigned int encodeLI(unsigned int loadIdx, unsigned int imm16, unsigned int rd) {
    unsigned int inst = 0;
    // bit 24 = 0
    inst |= (loadIdx & 0x7u) << 21;     // bits 23..21
    inst |= (imm16 & 0xFFFFu) << 5;     // bits 20..5
    inst |= (rd & 0x1Fu);               // bits 4..0 rd
    return inst;
}

// Convert 25-bit word to "010101..." string (MSB first)
string bits25ToString(unsigned int inst) {
    string s;
    s.resize(25);
    for (int i = 24; i >= 0; --i) {
        unsigned int bit = (inst >> i) & 1u;
        s[24 - i] = bit ? '1' : '0';
    }
    return s;
}

// ------------------------------------------------------------
// Assembler for a single line
// ------------------------------------------------------------

// Returns true if an instruction was produced, false if line is blank/comment/invalid
bool assembleLine(const string& originalLine, string& outBits, int lineNum, bool& hadError) {
    // Strip UTF-8 BOM if present at the start of the line
    string line = originalLine;
    if (line.size() >= 3 &&
        (unsigned char)line[0] == 0xEF &&
        (unsigned char)line[1] == 0xBB &&
        (unsigned char)line[2] == 0xBF) {
        line = line.substr(3);
    }

    string noComment = stripComments(line);
    string t = trim(noComment);

    if (t.empty()) return false;
    if (t[0] == '#') return false;

    vector<string> tok = tokenize(t);
    if (tok.empty()) return false;

    string mnUpper = toUpperStr(tok[0]);

    // LI: LI rd, imm16, loadIdx
    if (mnUpper == "LI") {
        if (tok.size() < 4) {
            cerr << "Error on line " << lineNum << ": LI requires rd, imm16, loadIdx" << endl;
            hadError = true;
            return false;
        }
        unsigned int rd = (unsigned int)parseReg(tok[1]);
        unsigned int imm16 = (unsigned int)parseImm16(tok[2]);
        unsigned int loadIdx = (unsigned int)parseLoadIndex(tok[3]);

        unsigned int inst = encodeLI(loadIdx, imm16, rd);
        outBits = bits25ToString(inst);
        return true;
    }

    // R4: MADDL rd, rs1, rs2, rs3
    int op4 = opcodeR4(mnUpper);
    if (op4 >= 0) {
        if (tok.size() < 5) {
            cerr << "Error on line " << lineNum << ": " << mnUpper
                << " requires rd, rs1, rs2, rs3" << endl;
            hadError = true;
            return false;
        }
        unsigned int rd = (unsigned int)parseReg(tok[1]);
        unsigned int rs1 = (unsigned int)parseReg(tok[2]);
        unsigned int rs2 = (unsigned int)parseReg(tok[3]);
        unsigned int rs3 = (unsigned int)parseReg(tok[4]);

        unsigned int inst = encodeR4((unsigned int)op4, rd, rs1, rs2, rs3);
        outBits = bits25ToString(inst);
        return true;
    }

    // R3 group: NOP, SHRHI, AU, AHS, OR, etc
    int opc = opcodeR3(mnUpper);
    if (opc >= 0) {
        // NOP: no operands
        if (mnUpper == "NOP") {
            if (tok.size() != 1) {
                cerr << "Warning on line " << lineNum
                    << ": NOP should not have operands; ignoring them." << endl;
            }
            unsigned int inst = encodeR3((unsigned int)opc, 0u, 0u, 0u);
            outBits = bits25ToString(inst);
            return true;
        }

        // SHRHI uses a 4-bit immediate shamt from instr(13..10)
        if (mnUpper == "SHRHI") {
            if (tok.size() < 4) {
                cerr << "Error on line " << lineNum
                    << ": SHRHI requires rd, rs1, shamt" << endl;
                hadError = true;
                return false;
            }
            unsigned int rd = (unsigned int)parseReg(tok[1]);
            unsigned int rs1 = (unsigned int)parseReg(tok[2]);

            int shamt = strToInt(tok[3]);
            if (shamt < 0)  shamt = 0;
            if (shamt > 15) shamt = 15;  // 4-bit shift amount

            // Place shamt in the rs2 field; ALU uses instr(13..10) as shamt
            unsigned int rs2_field = (unsigned int)shamt;

            unsigned int inst = encodeR3((unsigned int)opc, rd, rs1, rs2_field);
            outBits = bits25ToString(inst);
            return true;
        }

        //BCW case
        if (mnUpper == "BCW") {
            if (tok.size() < 3) {
                cerr << "Error on line " << lineNum
                    << ": BCW requires rd, rs1" << endl;
                hadError = true;
                return false;
            }
            unsigned int rd = (unsigned int)parseReg(tok[1]);
            unsigned int rs1 = (unsigned int)parseReg(tok[2]);
            unsigned int rs2_field = 0u;

            unsigned int inst = encodeR3((unsigned int)opc, rd, rs1, rs2_field);
            outBits = bits25ToString(inst);
            return true;
        }

        // MLHCU case
        if (mnUpper == "MLHCU") {
            if (tok.size() < 4) {
                cerr << "Error on line " << lineNum
                    << ": MLHCU requires rd, rs1, imm5" << endl;
                hadError = true;
                return false;
            }
            unsigned int rd = (unsigned int)parseReg(tok[1]);
            unsigned int rs1 = (unsigned int)parseReg(tok[2]);

            int imm5 = strToInt(tok[3]);
            if (imm5 < 0)  imm5 = 0;
            if (imm5 > 31) imm5 = 31;

            unsigned int rs2_field = (unsigned int)imm5;

            unsigned int inst = encodeR3((unsigned int)opc, rd, rs1, rs2_field);
            outBits = bits25ToString(inst);
            return true;
        }

        // General R3: OP rd, rs1, rs2
        if (tok.size() < 4) {
            cerr << "Error on line " << lineNum << ": " << mnUpper
                << " requires rd, rs1, rs2" << endl;
            hadError = true;
            return false;
        }
        unsigned int rd = (unsigned int)parseReg(tok[1]);
        unsigned int rs1 = (unsigned int)parseReg(tok[2]);
        unsigned int rs2 = (unsigned int)parseReg(tok[3]);

        unsigned int inst = encodeR3((unsigned int)opc, rd, rs1, rs2);
        outBits = bits25ToString(inst);
        return true;
    }

    // Unknown mnemonic
    cerr << "Error on line " << lineNum << ": unknown mnemonic '" << tok[0] << "'" << endl;
    hadError = true;
    return false;
}

// ------------------------------------------------------------
// main()
// ------------------------------------------------------------

int main() {
    const string inName = "program.asm";
    const string outName = "program.bin";

    ifstream fin(inName.c_str());
    if (!fin) {
        cout << "Failed to open input file: " << inName << endl;
        return 1;
    }

    ofstream fout(outName.c_str());
    if (!fout) {
        cout << "Failed to open output file: " << outName << endl;
        return 1;
    }

    string line;
    int lineNum = 0;
    int instCount = 0;
    bool hadError = false;

    while (std::getline(fin, line)) {
        lineNum++;
        string bits;
        bool produced = assembleLine(line, bits, lineNum, hadError);
        if (produced) {
            fout << bits << "\n";
            instCount++;
        }
    }

    cout << "Assembly finished. Wrote " << instCount
        << " instructions to " << outName << endl;

    if (hadError) {
        cout << "One or more errors occurred during assembly. "
            << "Check the messages above." << endl;
        return 1;
    }

    return 0;
}
