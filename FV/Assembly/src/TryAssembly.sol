// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {INftMarketplace} from "./INftMarketplace.sol";
// import "forge-std/console.sol";

/*
 * @title NftMarketplace
 * @auth Patrick Collins
 * @notice This contract allows users to list NFTs for sale
 * @notice This is the reference
 */
contract TryAssembly is INftMarketplace {
    error NftMarketplace__PriceNotMet(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    );
    error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
    error NftMarketplace__NoProceeds();
    error NftMarketplace__NotOwner();
    error NftMarketplace__PriceMustBeAboveZero();
    error NftMarketplace__TransferFailed();

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemUpdated(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    mapping(address nftAddress => mapping(uint256 tokenId => Listing))
        private s_listings;
    mapping(address seller => uint256 proceedAmount) private s_proceeds;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /*
     * @notice Method for listing NFT
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     */
    function listItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        bytes32 slot;
        assembly {
            if iszero(gt(price, 0)) {
                let ptr := mload(0x40)
                mstore(ptr, 0x096d7ecf)
                revert(add(ptr, 0x1c), 0x4)
            }
            slot := s_listings.slot
        }

        bytes32 location = keccak256(
            abi.encode(
                tokenId,
                keccak256(abi.encode(nftAddress, uint256(slot)))
            )
        );

        assembly {
            sstore(location, price)
            sstore(add(location, 1), caller())

            let ptr := mload(0x40)
            mstore(ptr, price)
            log4(
                ptr,
                0x20,
                // keccak256("ItemListed(address,address,uint256,uint256)")
                0xd547e933094f12a9159076970143ebe73234e64480317844b0dcb36117116de4,
                caller(),
                nftAddress,
                tokenId
            )
        }

        // Interactions (External)
        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    /*
     * @notice Method for cancelling listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     *
     * @audit-known seller can front-run a bought NFT and cancel the listing
     */
    function cancelListing(address nftAddress, uint256 tokenId) external {
        bytes32 slot;
        assembly {
            slot := s_listings.slot
        }

        bytes32 location = keccak256(
            abi.encode(
                tokenId,
                keccak256(abi.encode(nftAddress, uint256(slot)))
            )
        );

        assembly {
            let addr := sload(add(location, 1))
            if iszero(eq(addr, caller())) {
                let ptr := mload(0x40)
                mstore(ptr, 0x94953b60)
                revert(add(ptr, 0x1c), 0x4)
            }
            sstore(location, 0)
            sstore(add(location, 1), 0)
            log4(
                0,
                0,
                // keccak256("ItemCanceled(address,address,uint256)")
                0x9ba1a3cb55ce8d63d072a886f94d2a744f50cddf82128e897d0661f5ec623158,
                caller(),
                nftAddress,
                tokenId
            )
        }

        // Interactions (External)
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    /*
     * @notice Method for buying listing
     * @notice The owner of an NFT could unapprove the marketplace,
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function buyItem(address nftAddress, uint256 tokenId) external payable {
        bytes32 slot;
        assembly {
            slot := s_listings.slot
        }

        bytes32 location = keccak256(
            abi.encode(
                tokenId,
                keccak256(abi.encode(nftAddress, uint256(slot)))
            )
        );

        uint256 price;
        address seller;

        assembly {
            price := sload(location)
            seller := sload(add(location, 1))

            if iszero(seller) {
                let ptr := mload(0x40)
                mstore(ptr, 0x6d350f22)
                mstore(add(ptr, 0x20), nftAddress)
                mstore(add(ptr, 0x40), tokenId)
                revert(add(ptr, 0x1c), 0x44)
            }

            if lt(callvalue(), price) {
                let ptr := mload(0x40)
                mstore(ptr, 0x817ce9f1)
                mstore(add(ptr, 0x20), nftAddress)
                mstore(add(ptr, 0x40), tokenId)
                mstore(add(ptr, 0x60), price)
                revert(add(ptr, 0x1c), 0x64)
            }

            slot := s_proceeds.slot
        }

        bytes32 location2 = keccak256(abi.encode(seller, uint256(slot)));

        assembly {
            let proceeds := sload(location2)
            sstore(location2, add(proceeds, price))
            sstore(location, 0)
            sstore(add(location, 1), 0)

            let ptr := mload(0x40)
            mstore(ptr, price)
            log4(
                ptr,
                0x20,
                // keccak256("ItemBought(address,address,uint256,uint256)")
                0x263223b1dd81e51054a4e6f791d45a4a1ddb4aadcd93a2dfd892615c3fdac187,
                caller(),
                nftAddress,
                tokenId
            )
        }

        // Interactions (External)
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }

    /*
     * @notice Method for updating listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     *
     * @audit-known seller can front-run a bought NFT and update the listing
     */
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    ) external {
        // Checks
        address seller = s_listings[nftAddress][tokenId].seller;
        assembly{
            if iszero(gt(newPrice, 0)) {
                let ptr:= mload(0x40)
                mstore(ptr, 0x096d7ecf)
                revert(add(ptr, 0x1c), 0x4)
            }
            if iszero(eq(seller, caller())) {
                let ptr:= mload(0x40)
                mstore(ptr, 0x94953b60)
                revert(add(ptr, 0x1c), 0x4)
            }
        }

        // Effects (Internal)
        s_listings[nftAddress][tokenId].price = newPrice;

        assembly{
            let ptr:= mload(0x40)
            mstore(ptr, newPrice)
            log4(
                ptr,
                0x20,
                // keccak256("ItemUpdated(address,address,uint256,uint256)")
                0x3c33e65e8698294810b631d476d60b44425303828da0b1f8b635231bfda12be2,
                caller(),
                nftAddress,
                tokenId
            )
        }
    }

    /*
     * @notice Method for withdrawing proceeds from sales
     *
     * @audit-known, we should emit an event for withdrawing proceeds
     */
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        assembly {
            if iszero(proceeds) {
                let ptr := mload(0x40)
                mstore(ptr, 0x668a7c42)
                revert(add(ptr, 0x1c), 0x4)
            }
        }
    
        // require(address(this).balance >= proceeds, "Insufficient balance for withdrawal");

        assembly{
            let success := call(gas(), caller(), proceeds, 0, 0, 0, 0)
            if iszero(success) {
                let ptr := mload(0x40)
                mstore(ptr, 0xa05884ba)
                revert(add(ptr, 0x1c), 0x4)
            }
        }
        // Effects (Internal)
        s_proceeds[msg.sender] = 0;
        // // Interactions (External)
        // (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        // if (!success) {
        //     revert NftMarketplace__TransferFailed();
        // }
    }

    function onERC721Received(
        address,
        /*operator*/ address,
        /*from*/ uint256,
        /*tokenId*/ bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getListing(
        address nftAddress,
        uint256 tokenId
    ) external view returns (Listing memory) {
        bytes32 slot;
        assembly {
            slot := s_listings.slot
        }

        bytes32 location = keccak256(
            abi.encode(
                tokenId,
                keccak256(abi.encode(nftAddress, uint256(slot)))
            )
        );

        assembly {
            let price := sload(location)
            let seller := sload(add(location, 1))
            let ptr := mload(0x40)
            mstore(ptr, price)
            mstore(add(ptr, 0x20), seller)
            return(ptr, 0x40)
        }
    }

    function getProceeds(address seller) external view returns (uint256) {
        bytes32 slot;
        assembly {
            slot := s_proceeds.slot
        }

        bytes32 location2 = keccak256(abi.encode(seller, uint256(slot)));

        assembly {
            let proceeds := sload(location2)
            let ptr := mload(0x40)
            mstore(ptr, proceeds)
            return(ptr, 0x20)
        }
    }
}
