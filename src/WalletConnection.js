import React from 'react';

function WalletConnection({ provider, address }) {
  const connectWallet = async () => {
    if (provider) {
      await provider.send("eth_requestAccounts", []);
    }
  };

  return (
    <div className="wallet-connection">
      {address ? (
        <p className="text-sm text-gray-600">Connected: {address}</p>
      ) : (
        <button 
          onClick={connectWallet}
          className="w-full bg-blue-500 text-white rounded-md px-4 py-2 hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50"
        >
          Connect Wallet
        </button>
      )}
    </div>
  );
}

export default WalletConnection;