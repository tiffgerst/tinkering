/*
 * Certora Formal Verification Spec for GasBadNftMarketplace
 *
 * This spec is technically unsound because we make summaries about the functions, and are using optimistic fallback
 */ 

using GasBadNftMarketplace as gasBadMarketplace; 
using NftMock as nft;
using TryAssembly as ta;
using NftMarketplace as marketplace;

// Part of the contract but for certora
ghost mathint listingUpdatesCount {
    init_state axiom listingUpdatesCount == 0;
}
ghost mathint log4Count {
    init_state axiom log4Count == 0;
}

methods {
    function buyItem(address,uint256) external;
    function cancelListing(address,uint256) external;
    function listItem(address,uint256,uint256) external;
    function withdrawProceeds() external;
    function updateListing(address,uint256,uint256) external;

    // View Functions
    function getListing(address,uint256) external returns (INftMarketplace.Listing) envfree;
    function getProceeds(address) external returns (uint256) envfree;

    // summary format that tells tool what the function can and can't do
    function _.safeTransferFrom(address,address,uint256) external => DISPATCHER(true);
    function _.onERC721Received(address, address, uint256, bytes) external => DISPATCHER(true);
}

// anytime this opcode happens with these parameters, do something
hook Sstore s_listings[KEY address nftAddress][KEY uint256 tokenId].price uint256 price {
    listingUpdatesCount = listingUpdatesCount + 1;
}

hook LOG4(uint offset, uint length, bytes32 t1, bytes32 t2, bytes32 t3, bytes32 t4) uint v {
    log4Count = log4Count + 1;
}


invariant anytime_mapping_updated_emit_event() 
    listingUpdatesCount <= log4Count;


// parametric rules contain undefined method variables
// we can filter out functions by using filtered {}, which are like requires
rule calling_any_function_should_result_in_each_contract_having_the_same_state(method f, method f3, address listingAddr, uint256 tokenId, address seller){
    require(f.selector == f3.selector);
    env e;
    calldataarg args;

    // They start in the same state
    // require(gasBadMarketplace.getProceeds(e, seller) == marketplace.getProceeds(e, seller));
    require(ta.getProceeds(e, seller) == marketplace.getProceeds(e, seller));
    // require(gasBadMarketplace.getListing(e, listingAddr, tokenId).price == marketplace.getListing(e, listingAddr, tokenId).price);
    require(ta.getListing(e, listingAddr, tokenId).price == marketplace.getListing(e, listingAddr, tokenId).price);
    // require(gasBadMarketplace.getListing(e, listingAddr, tokenId).seller == marketplace.getListing(e, listingAddr, tokenId).seller);
    require(ta.getListing(e, listingAddr, tokenId).seller == marketplace.getListing(e, listingAddr, tokenId).seller);

    // It's the same function on each
    // require(f.selector == f2.selector);
    require(f.selector == f3.selector);
    // gasBadMarketplace.f(e, args);
    marketplace.f(e, args);
    ta.f3(e, args);

    // They end in the same state
    // assert(gasBadMarketplace.getListing(e, listingAddr, tokenId).price == marketplace.getListing(e, listingAddr, tokenId).price);
    assert(ta.getListing(e, listingAddr, tokenId).price == marketplace.getListing(e, listingAddr, tokenId).price);
    // assert(gasBadMarketplace.getListing(e, listingAddr, tokenId).seller == marketplace.getListing(e, listingAddr, tokenId).seller);
    assert(ta.getListing(e, listingAddr, tokenId).seller == marketplace.getListing(e, listingAddr, tokenId).seller);
    // assert(gasBadMarketplace.getProceeds(e, seller) == marketplace.getProceeds(e, seller));
    assert(ta.getProceeds(e, seller) == marketplace.getProceeds(e, seller));
}

// // The methods that we acknowledge in CVL 
// methods {
//     function buyItem(address,uint256) external;
//     function cancelListing(address,uint256) external;
//     function listItem(address,uint256,uint256) external;
//     function withdrawProceeds() external;
//     function updateListing(address,uint256,uint256) external;

//     // View Functions
//     function getListing(address,uint256) external returns (INftMarketplace.Listing) envfree;
//     function getProceeds(address) external returns (uint256) envfree;

//     // View Summary Example
//     function _.onERC721Received(address, address, uint256, bytes) external => ALWAYS(1); 
//     // Dispatcher Summary Example, means the safeTransferFrom function will only be called by an NftMock
//     function _.safeTransferFrom(address,address,uint256) external => DISPATCHER(true);
// }

// // Wait... why doesn't this work?
// // ghost mathint listingUpdatesCount;
// ghost mathint listingUpdatesCount {
//     // Axioms are CVL expressions that the tool will then assume are true about the ghost
//     // init_state refers to the initial state of the ghost
//     init_state axiom listingUpdatesCount == 0;
// }

// // we could make these persistent as a work around as well
// ghost mathint log4Count {
//     init_state axiom log4Count == 0;
// }

// // Can't do `s_listings[KEY address nftAddress][KEY uint256 tokenId]` since that returns a struct
// hook Sstore s_listings[KEY address nftAddress][KEY uint256 tokenId].price uint256 price STORAGE {
//     listingUpdatesCount = listingUpdatesCount + 1;
// }

// // Hooks don't get applied sequentially. 
// hook LOG4(uint offset, uint length, bytes32 t1, bytes32 t2, bytes32 t3, bytes32 t4) uint v {
//     log4Count = log4Count + 1;
// }

// /*//////////////////////////////////////////////////////////////
//                                 RULES
// //////////////////////////////////////////////////////////////*/

// // It shouldn't be possible to have more storage updates than events
// invariant anytime_mapping_updated_emit_event() 
//     listingUpdatesCount <= log4Count;



// rule calling_any_function_should_result_in_each_contract_having_the_same_state(method f, method f2, address listingAddr, uint256 tokenId, address seller){
//     env e;
//     calldataarg args;

//     // They start in the same state
//     require(gasBadMarketplace.getProceeds(e, seller) == marketplace.getProceeds(e, seller));
//     require(gasBadMarketplace.getListing(e, listingAddr, tokenId).price == marketplace.getListing(e, listingAddr, tokenId).price);
//     require(gasBadMarketplace.getListing(e, listingAddr, tokenId).seller == marketplace.getListing(e, listingAddr, tokenId).seller);

//     // It's the same function on each
//     require(f.selector == f2.selector);
//     gasBadMarketplace.f(e, args);
//     marketplace.f2(e, args);

//     // They end in the same state
//     assert(gasBadMarketplace.getListing(e, listingAddr, tokenId).price == marketplace.getListing(e, listingAddr, tokenId).price);
//     assert(gasBadMarketplace.getListing(e, listingAddr, tokenId).seller == marketplace.getListing(e, listingAddr, tokenId).seller);
//     assert(gasBadMarketplace.getProceeds(e, seller) == marketplace.getProceeds(e, seller));
// }


// run with
// # "prover_args": [
//     #     "-optimisticFallback true"
//     # ]