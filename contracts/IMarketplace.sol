// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./IThirdwebContract.sol";
import "./IPlatformFee.sol";

interface IMarketplace is IThirdwebContract, IPlatformFee {
    /// @notice Type of the tokens that can be listed for sale.
    enum TokenType {
        ERC1155,
        ERC721
    }

    /**
     *  @notice One Listing Type.
     *          `Loctok` (0): NFTs listed for sale in at a location with a fixed price using a google plus code.
     */
    enum ListingType {
        Loctok
    }

    /**
     *  @notice The information related to an offer on a direct listing at a location.
     *
     *  @dev The type of the listing at ID `lisingId` determins how the `Offer` is interpreted.
     *      If the listing is of type `Loctok`, the `Offer` is interpreted as an offer to a direct listing at a google plus code location.
     *
     *  @param listingId      The uid of the listing the offer is made to.
     *  @param offeror        The account making the offer.
     *  @param quantityWanted The quantity of tokens from the listing wanted by the offeror.
     *  @param currency       The currency in which the offer is made.
     *  @param pricePerToken  The price per token offered to the lister.
     *  @param expirationTimestamp The timestamp after which a seller cannot accept this offer.
     *  @param plusCode       The google plus code of the location of the listing.
     */
    struct Offer {
        uint256 listingId;
        address offeror;
        uint256 quantityWanted;
        address currency;
        uint256 pricePerToken;
        uint256 expirationTimestamp;
        string plusCode;
    }

    /**
     *  @dev For use in `createListing` as a parameter type.
     *
     *  @param assetContract         The contract address of the NFT to list for sale.

     *  @param tokenId               The tokenId on `assetContract` of the NFT to list for sale.

     *  @param startTime             The unix timestamp after which the listing is active. For direct listings:
     *                               'active' means NFTs can be bought from the listing.
     *
     *  @param secondsUntilEndTime   No. of seconds after `startTime`, after which the listing is inactive.
     *                               For direct listings: 'inactive' means NFTs cannot be bought from the listing.
     *
     *  @param quantityToList        The quantity of NFT of ID `tokenId` on the given `assetContract` to list. For
     *                               ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                               Regardless of the value of `quantityToList` passed.
     *
     *  @param currencyToAccept      For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                               to buy the NFT(s).
     *
     *  @param reservePricePerToken  For direct listings: this value is ignored.
     *
     *  @param buyoutPricePerToken   For direct listings: interpreted as 'price per token' listed.
     *
     *  @param listingType           The type of listing to create - a direct loctok listing.
     *
     *
     *  @param plusCode              The google plus code of the location of the listing. For other listings: this value is ignored.
    **/
    struct ListingParameters {
        address assetContract;
        uint256 tokenId;
        uint256 startTime;
        uint256 secondsUntilEndTime;
        uint256 quantityToList;
        address currencyToAccept;
        uint256 reservePricePerToken;
        uint256 buyoutPricePerToken;
        string plusCode;
        ListingType listingType;
    }

    /**
     *  @notice The information related to a listing; either (0) a direct listing at a location based listing.
     *
     *  @dev For direct listings:
     *          (1) `reservePricePerToken` is ignored.
     *          (2) `buyoutPricePerToken` is simply interpreted as 'price per token'.
     *
     *  @param listingId             The uid for the listing.
     *
     *  @param tokenOwner            The owner of the tokens listed for sale.  
     *
     *  @param assetContract         The contract address of the NFT to list for sale.

     *  @param tokenId               The tokenId on `assetContract` of the NFT to list for sale.

     *  @param startTime             The unix timestamp after which the listing is active. For direct listings:
     *                               'active' means NFTs can be bought from the listing.
     *
     *  @param endTime               The timestamp after which the listing is inactive.
     *                               For direct listings: 'inactive' means NFTs cannot be bought from the listing.
     *
     *  @param quantity              The quantity of NFT of ID `tokenId` on the given `assetContract` listed. For
     *                               ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                               Regardless of the value of `quantityToList` passed.
     *
     *  @param currency              For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                               to buy the NFT(s).
     *
     *  @param reservePricePerToken  For direct listings: this value is ignored.
     *
     *  @param buyoutPricePerToken   For direct listings: interpreted as 'price per token' listed.
     *
     *  @param tokenType             The type of the token(s) listed for for sale -- ERC721 or ERC1155 
     *
     *  @param listingType            The type of listing to create - a direct listing at a location.
     *  @param plusCode              The google plus code of the location of the listing. For other listings: this value is ignored.
    **/
    struct Listing {
        uint256 listingId;
        address tokenOwner;
        address assetContract;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 quantity;
        address currency;
        uint256 reservePricePerToken;
        uint256 buyoutPricePerToken;
        string plusCode;
        TokenType tokenType;
        ListingType listingType;
    }

    /// @dev Emitted when a new listing is created.
    event ListingAdded(
        uint256 indexed listingId,
        address indexed assetContract,
        address indexed lister,
        Listing listing
    );

    /// @dev Emitted when the parameters of a listing are updated.
    event ListingUpdated(uint256 indexed listingId, address indexed listingCreator);

    /// @dev Emitted when a listing is cancelled.
    event ListingRemoved(uint256 indexed listingId, address indexed listingCreator);

    /**
     * @dev Emitted when a buyer buys from a direct listing, or a lister accepts some
     *      buyer's offer to their direct listing.
     */
    event NewSale(
        uint256 indexed listingId,
        address indexed assetContract,
        address indexed lister,
        address buyer,
        uint256 quantityBought,
        uint256 totalPricePaid
    );

    /// @dev Emitted when a new offer is made to a direct loctok listing is made.
    event NewOffer(
        uint256 indexed listingId,
        address indexed offeror,
        ListingType indexed listingType,
        uint256 quantityWanted,
        uint256 totalOfferAmount,
        address currency
    );


    /**
     *  @notice Lets a token owner list tokens (ERC 721 or ERC 1155) for sale in a direct loctok listing.
     *
     *  @dev For direct listings, the contract only checks whether the listing's creator owns and has approved Marketplace to transfer the NFTs to list.
     *
     *  @param _params The parameters that govern the listing to be created.
     */
    function createListing(ListingParameters memory _params) external;

    /**
     *  @notice Lets a listing's creator edit the listing's parameters. A direct listing can be edited whenever.
     *
     *  @param _listingId            The uid of the lisitng to edit.
     *
     *  @param _quantityToList       The amount of NFTs to list for sale in the listing. For direct lisitngs, the contract
     *                               only checks whether the listing creator owns and has approved Marketplace to transfer
     *                               `_quantityToList` amount of NFTs to list for sale.
     *
     *  @param _reservePricePerToken For direct listings: this value is ignored.
     *
     *  @param _buyoutPricePerToken  For direct listings: interpreted as 'price per token' listed.
     *
     *  @param _currencyToAccept     For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                               to buy the NFT(s).
     *
     *  @param _startTime            The unix timestamp after which listing is active.
     *
     *  @param _secondsUntilEndTime  No. of seconds after the provided `_startTime`, after which the listing is inactive.
     *                               For direct listings: 'inactive' means NFTs cannot be bought from the listing.
     */
    function updateListing(
        uint256 _listingId,
        uint256 _quantityToList,
        uint256 _reservePricePerToken,
        uint256 _buyoutPricePerToken,
        address _currencyToAccept,
        uint256 _startTime,
        uint256 _secondsUntilEndTime
    ) external;

    /**
     *  @notice Lets a direct listing creator cancel their listing.
     *
     *  @param _listingId The unique Id of the lisitng to cancel.
     */
    function cancelDirectListing(uint256 _listingId) external;

    /**
     *  @notice Lets someone buy a given quantity of tokens from a direct listing by paying the fixed price.
     *
     *  @param _listingId The uid of the direct lisitng to buy from.
     *  @param _buyFor The receiver of the NFT being bought.
     *  @param _quantity The amount of NFTs to buy from the direct listing.
     *  @param _currency The currency to pay the price in.
     *  @param _totalPrice The total price to pay for the tokens being bought.
     *
     *  @dev A sale will fail to execute if either:
     *          (1) buyer does not own or has not approved Marketplace to transfer the appropriate
     *              amount of currency (or hasn't sent the appropriate amount of native tokens)
     *
     *          (2) the lister does not own or has removed Markeplace's
     *              approval to transfer the tokens listed for sale.
     */
    function buy(
        uint256 _listingId,
        address _buyFor,
        uint256 _quantity,
        address _currency,
        uint256 _totalPrice
    ) external payable;

    /**
     *  @notice Lets someone make an offer to a direct listing.
     *
     *  @dev Each (address, listing ID) pair maps to a single unique offer. So e.g. if a buyer makes
     *       makes two offers to the same direct listing, the last offer is counted as the buyer's
     *       offer to that listing.
     *
     *  @param _listingId        The unique ID of the lisitng to make an offer to.
     *
     *  @param _quantityWanted   For direct listings: `_quantityWanted` is the quantity of NFTs from the
     *                           listing, for which the offer is being made.
     *
     *  @param _currency         For direct listings: this is the currency in which the offer is made.
     *
     *  @param _pricePerToken    For direct listings: offered price per token.
     *
     *  @param _expirationTimestamp For direct listings: The timestamp after which
     *                              the seller can no longer accept the offer.
     */
    function offer(
        uint256 _listingId,
        uint256 _quantityWanted,
        address _currency,
        uint256 _pricePerToken,
        uint256 _expirationTimestamp,
        string  calldata _plusCode
    ) external payable;

    /**
     * @notice Lets a listing's creator accept an offer to their direct listing.
     * @param _listingId The unique ID of the listing for which to accept the offer.
     * @param _offeror The address of the buyer whose offer is to be accepted.
     * @param _currency The currency of the offer that is to be accepted.
     * @param _totalPrice The total price of the offer that is to be accepted.
     */
    function acceptOffer(
        uint256 _listingId,
        address _offeror,
        address _currency,
        uint256 _totalPrice
    ) external;

}