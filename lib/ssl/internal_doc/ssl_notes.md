<!--
%% %CopyrightBegin%
%%
%% SPDX-License-Identifier: Apache-2.0
%%
%% Copyright Ericsson AB 2024-2025. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% %CopyrightEnd%
-->
# ssl dev notes
## client-side OCSP stapling
1. stapling - is ssl option holding configuration provided by user
   - ocsp_nonce :: true|false
2. stapling_state - holds handshake process data
   - status :: not_negotiated | negotiated | not_received | received_staple
   - ocsp_nonce :: binary()
3. stapling_info - holds date required for verifying the certificate chain

```mermaid
classDiagram
    stapling .. stapling_state
    stapling_state ..* stapling_info

    stapling: ocsp_nonce
    note for stapling "- stapling option is a boolean or a map\n- map is interpreted as stapling enabled\n- ocsp_nonce is boolean"
    stapling_state: configured
    stapling_state: ocsp_nonce
    note for stapling_state "ocsp_nonce is random binary"
    stapling_state: status
    stapling_state: response
    stapling_info: cert_ext #{SubjectId => Status}
```
## ssl test certificates
- test certificates are generated by `ssl/test/make_certs.erl/`

```mermaid
---
title: Test certs
---
flowchart RL
   localhost["`2:localhost
               3:localhost`"] --> erlangCA[["BIG_RAND_SERIAL:erlangCA"]]
   otpCA[[1:otpCA]] --> erlangCA
   client["`1:client
            2:client`"] --> otpCA
   server["`3:server
            4:server`"] --> otpCA
   aserver["`9:a.server
             10:a.server`"] --> otpCA
   bserver["`11:b.server
             12:b.server`"] --> otpCA
   revoked["`5:revoked
             6:revoked`"] --> otpCA
   undetermined["`7:undetermined
                  8:undetermined`"] --> otpCA
```

## Notes on the PEM and cert caches
### Data relations

     |---------------|                 |------------------------|
     | PemCache      |                 | CertDb                 |
     |---------------|               * |------------------------|
     | FilePath (PK) |           +---- | {Ref, SN, Issuer} (PK) |
     | FileContent   |           |     | Cert (Subject)         |
     |---------------|           |     |------------------------|
        |0,1                     |
        |            +-----------+
        |0,1         |1
     |-----------------|               |------------|
     | FileMapDb       |               | RefDb      |
     |-----------------|1           1  |------------|
     | CaCertFile (PK) |---------------| Ref (PK)   |
     | Ref (FK)        |               | Counter    |
     |-----------------|               |------------|

#### PemCache
1. stores a copy of file content in memory
2. includes files from cacertfile, certfile, keyfile options
3. content is added unless FileMapDb table contains entry with specified path

#### FileMapDb
1. holds relation between specific path (PEM file with CA certificates) and a ref
2. ref is generated when file from path is added for 1st time
3. ref is used as path identifier in CertDb and RefDb tables

#### RefDb
1. holds an active connections counter for a specific ref
2. when counter reaches zero - related data in CertDb, FileMapDb, RefDb is deleted

#### CertDb
1. holds decoded CA ceritificates (only those taken from cacertfile option)
2. used for building certificate chains
3. it is an ETS set table - when iterating in search of Issuer certificate,
   processing order is not guaranted
4. Table key is: {Ref, SerialNumber, Issuer}
