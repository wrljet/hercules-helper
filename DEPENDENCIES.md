# Dependency locks

These identities are the repository defaults as of 2026-06-21. Archive changes
must update the URL and SHA-256 together. Git changes must update the exact
commit in every affected configuration.

## Main build

| Component | Source identity |
|---|---|
| SDL Hyperion | `5744d9b216a3dc38f6c4f96849b1eb94abe7a6c6` |
| Hercules Aethra | `2be74b0c508bf658e12cab5a1ae164a0e6c83225` |
| GNU Hurd Hercules | `b89456ede863428458be3c5e602c030c3fc4831c` |
| extpkg crypto | `9ac58405c2b91fb7cd230aed474dc7059f0fcad9` |
| extpkg decNumber | `995184583107625015bb450228a5f3fb781d9502` |
| extpkg SoftFloat | `e053494d988ec0648c92f683abce52597bfae745` |
| extpkg telnet | `384b2542dfc9af67ca078e2bc13487a8fc234a3f` |
| Regina REXX 3.9.7 source | SHA-256 `f13701ebd542e74d0fc83b2a7876a812b07d21e43400275ed65b1ac860204bd4` |

## Standalone helpers

| Component | Source identity |
|---|---|
| suite3270 4.0ga13 | SHA-256 `eb39f1b65dfdc9b912301d7a7f269f4d92043223a5196bcfd7e8d7bdf2c95fcf` |
| suite3270 4.2ga7 | SHA-256 `68f16dd3bc75f50c054e8482711e76fcf5b4984aacc47a359fd94f01c9c0a429` |
| CMake 3.20.3 | SHA-256 `4d008ac3461e271fcfac26a05936f77fc7ab64402156fb371d41284851a651b8` |
| CMake 3.12.3 | SHA-256 `acbf13af31a741794106b76e5d22448b004a66485fc99f6d7df4d22e99da164a` |
| Nmap/Ncat 7.91 | SHA-256 `18cc4b5070511c51eb243cdd2b0b30ff9b2c4dc4544c6312f75ce3a67a593300` |
| Python 3.9.5 | SHA-256 `e0fbd5b6e1ee242524430dee3c91baf4cbbaba4a72dd1674b90fda87b713c7ab` |
| ooRexx trunk | Subversion revision `13169` |
| lib3270 | `5a295e862cdb151eab05f5aad1d321be412dd5d9` |
| libv3270 | `b290a714b7b6ca4dd0f556dfae278c3a939ae458` |
| PW3270 | `88fc0c73b343188b3455770686dbc18f7536dc06` |

The CMake 3.12.3 digest is from Kitware's official
`cmake-3.12.3-SHA-256.txt` release manifest. Other archive digests were
verified against the exact maintained source objects before being committed.
