//SDX-License-Identifier: MIT

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Errors} from "lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testInitialSupply() public view {
        uint256 total = ourToken.totalSupply();
        assertGt(total, 0);
        // assertEq(ourToken.balanceOf(address(this)), total - STARTING_BALANCE);
    }

    function testMetadata() public view {
        assertEq(ourToken.name(), "myToken");
        assertEq(ourToken.symbol(), "MT");
        assertEq(ourToken.decimals(), 18);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testTransferBetweenAccounts() public {
        uint transferAmount = 10 ether;
        vm.prank(bob);
        ourToken.transfer(alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    function testInsufficientTransferShouldFail() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                alice,
                0,
                1 ether
            )
        );
        vm.prank(alice);
        ourToken.transfer(bob, 1 ether);
    }

    function testApproveAllowance() public {
        uint256 AllowanceAmount = 500 ether;
        vm.prank(bob);

        ourToken.approve(alice, AllowanceAmount);

        assertEq(ourToken.allowance(bob, alice), AllowanceAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 allowanceAmount = 500 ether;
        uint256 transferAmount = 20 ether;

        vm.prank(bob);
        ourToken.approve(alice, allowanceAmount);

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
        assertEq(
            ourToken.allowance(bob, alice),
            allowanceAmount - transferAmount
        );
    }

    function testTransferFromWithoutApprovalShouldFail() public {
        uint256 amount = 1 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                alice, // spender
                0, // current allowance
                amount // required allowance
            )
        );

        vm.prank(alice); // Alice tries to move funds from Bob
        ourToken.transferFrom(bob, alice, amount);
    }

    // test them

    function testOverwriteApprove() public {
        uint256 firstApproval = 100 ether;
        uint256 newApproval = 50 ether;

        vm.prank(bob);
        ourToken.approve(alice, firstApproval);
        assertEq(ourToken.allowance(bob, alice), firstApproval);

        vm.prank(bob);
        ourToken.approve(alice, newApproval);
        assertEq(ourToken.allowance(bob, alice), newApproval);
    }

    function testTransferToZeroAddressShouldFail() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector,
                address(0)
            )
        );

        vm.prank(bob);
        ourToken.transfer(address(0), 10 ether);
    }

    function testApproveToZeroAddressShouldFail() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidSpender.selector,
                address(0)
            )
        );

        vm.prank(bob);
        ourToken.approve(address(0), 10 ether);
    }

    function testTransferFromToZeroAddressShouldFail() public {
        // Setup: Give bob some tokens
        vm.prank(msg.sender); // assuming `owner` is deployer with initial supply
        ourToken.transfer(bob, 100 ether);

        // Setup: bob approves alice
        vm.prank(bob);
        ourToken.approve(alice, 100 ether);

        // Expect revert on invalid receiver
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InvalidReceiver.selector,
                address(0)
            )
        );

        // Try to transfer to zero address via transferFrom
        vm.prank(alice);
        ourToken.transferFrom(bob, address(0), 10 ether);
    }

    function testFuzzTransfer(uint256 amount) public {
        amount = bound(amount, 0, STARTING_BALANCE); // prevent overflow

        vm.prank(bob);
        bool success = ourToken.transfer(alice, amount);

        assertTrue(success);
        assertEq(ourToken.balanceOf(alice), amount);
    }

    
}
