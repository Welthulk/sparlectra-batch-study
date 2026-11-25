# Copyright 2026 Udo Schmitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# file: scripts/download_cases.jl
# purpose: download the MATPOWER case files of the study from the MATPOWER
#          release 8.1 on GitHub into data/ and check each against the
#          SHA-256 of the file that was measured. The case files are not part
#          of this repository; they keep the licenses stated in their headers
#          and in MATPOWER (see README, "Data").
# usage: julia scripts/download_cases.jl [case ...]   (default: all)
using Downloads, SHA

const TAG = "8.1"
const URL = "https://raw.githubusercontent.com/MATPOWER/matpower/$(TAG)/data/"
const CASES = Dict(
  "case118" => "bc2e6f22b4b9e776572885ee4b50e4f4ab2ee0c5577e9126e86d906f14c4b5f7",
  "case300" => "69a90280e999ef533d94656e0fbc08311f1347c962dd2753ff2005ff5e3f9ac5",
  "case_ACTIVSg500" => "8ca6d54ea5179eeb03fe29d7b645618e7a86338c172247e81687476660f6dcbe",
  "case1354pegase" => "1b08b25a2f6c1d540d090009dfaff41ff2b05784a2d8d302a7ad695821557b89",
  "case1888rte" => "df675cd826bb300e91596795ee3258a70deb81f0329dbc49ccf24c6048668037",
  "case_ACTIVSg2000" => "8d00618de8fd10bf35a599f59d2deebfecd0d86e28fcff73219ad7c4ebab860b",
  "case2869pegase" => "d205ccbc1c0386715393661d7bd6f1f879ebcdc5d6f0e3665fb0aaf2c4db0b64",
  "case6495rte" => "70d82b7415ba7d8e0ba3b13fbace8594002fe0f5990d307b9d0ec51d6897ffbf",
  "case9241pegase" => "593a58ecddb5af509ff94410a6630f81021b48fa31da0694ff516acfa9ea5f3b",
  "case_ACTIVSg10k" => "ead10b25fecc4dcc02f88bacdfb3526fe8b8985b81f7e539c95abddb32575590",
  "case_ACTIVSg25k" => "0b7c131ff6434491f5c0f76dedf67bff155d9cbb91ce67aef5ce275fd8bf3004",
  "case_ACTIVSg70k" => "5df8c785c75f174555d307e05ae279c51f888ebbd85c469dab3265baf3e96293",
)

function main(args)
  dir = joinpath(dirname(@__DIR__), "data")
  mkpath(dir)
  names = isempty(args) ? sort!(collect(keys(CASES))) : args
  bad = 0
  for name in names
    haskey(CASES, name) || error("unknown case $(name); known: $(join(sort!(collect(keys(CASES))), ", "))")
    path = joinpath(dir, name * ".m")
    isfile(path) || Downloads.download(URL * name * ".m", path)
    sum = bytes2hex(open(sha256, path))
    ok = sum == CASES[name]
    ok || (bad += 1)
    println(rpad(name, 18), ok ? "ok" : "CHECKSUM MISMATCH (delete the file and download again)")
  end
  bad == 0 || exit(1)
end

main(ARGS)
