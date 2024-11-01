object "HorseStoreYul" {
    code {
        datacopy(0, dataoffset("runtime"), datasize("runtime")) // take the object runtime, copy it into slot 0
        return(0, datasize("runtime"))
    }
    object "runtime" {
        code{
            switch selector()
            case 0xcdfead2e {
                storeNumber(decodeAsUint(0))
            }
            case 0xe026c017 {
                returnUint(readNumber())
            }
            default {
                revert(0, 0)
            }

            function storeNumber(newNumber) {
                sstore(0, newNumber)
            }

            function selector() -> s {
                s:= div(calldataload(0), 0x10000000000000000000000000000000000000000000000000000000)
            }
            function readNumber() -> storedNumber {
                storedNumber := sload(0)
            } 
            function decodeAsUint(offset) -> v {
                let positionInCallData := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(positionInCallData, 0x20)){
                    revert(0, 0)
                }
                v := calldataload(positionInCallData)
            }
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
        }
    }
}