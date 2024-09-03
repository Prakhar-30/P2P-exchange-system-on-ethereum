import React, { useState } from 'react';
import { ethers } from 'ethers';

function ContributionForm({ contract }) {
  const [amount, setAmount] = useState('');

  const handleContribute = async (e) => {
    e.preventDefault();
    try {
      const tx = await contract.contribute({ value: ethers.utils.parseEther(amount) });
      await tx.wait();
      alert('Contribution successful!');
      setAmount('');
    } catch (error) {
      console.error('Error:', error);
      alert('Contribution failed. Please try again.');
    }
  };

  return (
    <form onSubmit={handleContribute}>
      <input
        type="text"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="Amount in ETH"
        className="w-full px-3 py-2 placeholder-gray-300 border border-gray-300 rounded-md focus:outline-none focus:ring focus:ring-indigo-100 focus:border-indigo-300"
      />
      <button 
        type="submit"
        className="mt-2 w-full bg-indigo-500 text-white rounded-md px-4 py-2 hover:bg-indigo-600 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-opacity-50"
      >
        Get Service
      </button>
    </form>
  );
}

export default ContributionForm;