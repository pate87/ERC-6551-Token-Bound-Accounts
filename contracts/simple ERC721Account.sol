// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
165 is a standard to let others know "what" type of contract it is. ERC-20 contracts which implement 165 have one function to return a magic value, ERC-721 have their own magic value, and so on. i think you showed a magic value earlier, that is required and standardized through ERC-165 implementation
and 1271 is a "contract signer" standard since smart contracts cant sign messages its a standard that allows for a slightly roundabout way of getting contracts to "sign" messages by having a 'validateSignature'-type method in the contract
*/
import "@openzeppelin/contracts/utils/introspection/IERC165.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; 
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "https://github.com/erc6551/reference/blob/v0.2.0-deployment/src/interfaces/IERC6551Account.sol"; 
import "https://github.com/erc6551/reference/blob/v0.2.0-deployment/src/lib/ERC6551AccountLib.sol"; 
import "https://github.com/erc6551/reference/blob/v0.2.0-deployment/src/ERC6551Registry.sol";

contract SimpleERC6551Account is IERC165, IERC1271, IERC6551Account {

    uint public nonce;

    receive() external payable {}

    function executeCall(
        address to,
        uint value,
        bytes calldata data
    ) public payable returns (bytes memory result){
        if(msg.sender != owner()) {
            revert("Your not the owner");
        }

        ++nonce;

        /**
        Calls the Event from /IERC6551Account.sol
        */
        emit TransactionExecuted(to, value, data);

        bool success;

        (success, result) = to.call{value: value}(data);

        if(!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token() external view returns(uint, address, uint) {
        return ERC6551AccountLib.token();
    }

    function owner() public view returns(address) {
        (uint chainId, address tokenContract, uint tokenId) = this.token();
        if(chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

     function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
}