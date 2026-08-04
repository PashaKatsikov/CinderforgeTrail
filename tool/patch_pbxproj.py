#!/usr/bin/env python3
"""One-shot: wire GoogleService-Info.plist + PrivacyInfo.xcprivacy into Runner's
Copy Bundle Resources and attach Runner.entitlements to the 3 Runner configs.

Reads/writes as binary, no BOM, preserves tabs. Idempotent: refuses to double-add.
"""
import secrets
import sys

PBX = "ios/Runner.xcodeproj/project.pbxproj"


def uid() -> str:
    return secrets.token_hex(12).upper()


def main() -> int:
    raw = open(PBX, "rb").read()
    assert raw[:4] == b"// !", "unexpected pbxproj header / BOM"
    txt = raw.decode("utf-8")

    if "GoogleService-Info.plist in Resources" in txt:
        print("already patched — nothing to do")
        return 0

    gs_build, gs_ref = uid(), uid()
    pi_build, pi_ref = uid(), uid()
    ent_ref = uid()

    # 1 — PBXBuildFile (after the SceneDelegate build file line)
    anchor_bf = ("\t\t7884E8682EC3CC0700C636F2 /* SceneDelegate.swift in Sources */ "
                 "= {isa = PBXBuildFile; fileRef = 7884E8672EC3CC0400C636F2 /* SceneDelegate.swift */; };\n")
    add_bf = (
        f"\t\t{gs_build} /* GoogleService-Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {gs_ref} /* GoogleService-Info.plist */; }};\n"
        f"\t\t{pi_build} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {pi_ref} /* PrivacyInfo.xcprivacy */; }};\n"
    )
    assert anchor_bf in txt, "build-file anchor not found"
    txt = txt.replace(anchor_bf, anchor_bf + add_bf, 1)

    # 2 — PBXFileReference (after the Info.plist file reference line)
    anchor_fr = ("\t\t97C147021CF9000F007C117D /* Info.plist */ = {isa = PBXFileReference; "
                 "lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; };\n")
    add_fr = (
        f"\t\t{gs_ref} /* GoogleService-Info.plist */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = text.plist.xml; path = \"GoogleService-Info.plist\"; sourceTree = \"<group>\"; }};\n"
        f"\t\t{pi_ref} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = PrivacyInfo.xcprivacy; sourceTree = \"<group>\"; }};\n"
        f"\t\t{ent_ref} /* Runner.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Runner.entitlements; sourceTree = \"<group>\"; }};\n"
    )
    assert anchor_fr in txt, "file-ref anchor not found"
    txt = txt.replace(anchor_fr, anchor_fr + add_fr, 1)

    # 3 — Runner PBXGroup children (after Runner-Bridging-Header.h)
    anchor_grp = "\t\t\t\t74858FAD1ED2DC5600515810 /* Runner-Bridging-Header.h */,\n"
    add_grp = (
        f"\t\t\t\t{gs_ref} /* GoogleService-Info.plist */,\n"
        f"\t\t\t\t{pi_ref} /* PrivacyInfo.xcprivacy */,\n"
        f"\t\t\t\t{ent_ref} /* Runner.entitlements */,\n"
    )
    assert anchor_grp in txt, "group anchor not found"
    txt = txt.replace(anchor_grp, anchor_grp + add_grp, 1)

    # 4 — Runner Resources build phase (97C146EC…): after Main.storyboard line
    anchor_res = "\t\t\t\t97C146FC1CF9000F007C117D /* Main.storyboard in Resources */,\n"
    add_res = (
        f"\t\t\t\t{gs_build} /* GoogleService-Info.plist in Resources */,\n"
        f"\t\t\t\t{pi_build} /* PrivacyInfo.xcprivacy in Resources */,\n"
    )
    assert anchor_res in txt, "resources anchor not found"
    txt = txt.replace(anchor_res, anchor_res + add_res, 1)

    # 5 — CODE_SIGN_ENTITLEMENTS on the 3 Runner configs (each has this line)
    ent_anchor = "\t\t\t\tINFOPLIST_FILE = Runner/Info.plist;\n"
    ent_line = "\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n"
    count = txt.count(ent_anchor)
    assert count == 3, f"expected 3 Runner INFOPLIST_FILE lines, found {count}"
    txt = txt.replace(ent_anchor, ent_line + ent_anchor)

    out = txt.encode("utf-8")
    assert out[:3] != b"\xef\xbb\xbf", "refusing to write BOM"
    open(PBX, "wb").write(out)
    print("patched OK")
    print("CODE_SIGN_ENTITLEMENTS count:", txt.count("CODE_SIGN_ENTITLEMENTS"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
