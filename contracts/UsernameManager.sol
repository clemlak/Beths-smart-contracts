pragma solidity 0.5.8;


contract UsernameManager {
    mapping (string => address) private usernamesToAddresses;

    function claimUsername(string calldata username) external {
        usernamesToAddresses[username] = msg.sender;
    }

    function getAddressFromUsername(string calldata username) external view returns (address) {
        return usernamesToAddresses[username];
    }
}
