const NFDNS = artifacts.require("NFDNS");

contract('testing NFDNS', accounts => {

    let token;
    const name = "BlueCat";
    const symbol = "BCat"

    const account1 = accounts[1]
    const tokenUri1 = "token 1 URI"; 

    const account2 = accounts[2]
    const tokenUri2 = "token 2 URI";

    const account3 = accounts[3]

    it('should be able to deploy and mint ERC721 token', () => {
        NFDNS.deployed()
            .then(instance => instance.edomMint())
            .then(
                assert.equal()
            );


        token = await MyERC721.new(name, symbol)
        await token.mintUniqueTokenTo(account1, tokenId1, tokenUri1, {from: accounts[0]})

        expect(await token.symbol()).to.equal(symbol)
        expect(await token.name()).to.equal(name)
    });
        
        
    })

    it(' should be unique', async () => {
        const duplicateTokenID = token.mintUniqueTokenTo(account2, tokenId1, tokenUri2, {from: accounts[0]}) //tokenId
        expect(duplicateTokenID).to.be.rejectedWith(/VM Exception while processing transaction: revert/)
    })

    it(' should allow creation of multiple unique tokens and manage ownership', async () => {
        const additionalToken = await token.mintUniqueTokenTo(account2, tokenId2, tokenUri2, {from: accounts[0]})
        expect(Number(await token.totalSupply())).to.equal(2)

        expect(await token.exists(tokenId1)).to.be.true
        expect(await token.exists(tokenId2)).to.be.true
        expect(await token.exists(9999)).to.be.false // Dummy tokenId

        expect(await token.ownerOf(tokenId1)).to.equal(account1)
        expect(await token.ownerOf(tokenId2)).to.equal(account2)
    })

    it(' should allow safe transfers', async () => {
        const unownedTokenId = token.safeTransferFrom(account2, account3, tokenId1, {from: accounts[2]}) // tokenId
        expect(unownedTokenId).to.be.rejectedWith(/VM Exception while processing transaction: revert/)

        const wrongOwner = token.safeTransferFrom(account1, account3, tokenId2, {from: accounts[1]}) // wrong owner
        expect(wrongOwner).to.be.rejectedWith(/VM Exception while processing transaction: revert/)

        // Noticed that the from gas param needs to be the token owners or it fails
        const wrongFromGas = token.safeTransferFrom(account2, account3, tokenId2, {from: accounts[1]}) // wrong owner
        expect(wrongFromGas).to.be.rejectedWith(/VM Exception while processing transaction: revert/)

        await token.safeTransferFrom(account2, account3, tokenId2, {from: accounts[2]})
        expect(await token.ownerOf(tokenId2)).to.equal(account3)
    })
})