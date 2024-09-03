import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import ContributionForm from './ContributionForm';

function ContractCard({ name, address, contractABI, signer }) {
  const [contract, setContract] = useState(null);
  const [minimumContribution, setMinimumContribution] = useState('');
  const [totalContributions, setTotalContributions] = useState('');

  useEffect(() => {
    if (signer) {
      const contract = new ethers.Contract(address, contractABI, signer);
      setContract(contract);

      const fetchContractInfo = async () => {
        const minContribution = await contract.minimumContribution();
        setMinimumContribution(ethers.utils.formatEther(minContribution));

        const total = await contract.totalContributions();
        setTotalContributions(ethers.utils.formatEther(total));
      };

      fetchContractInfo();
    }
  }, [signer, address, contractABI]);

  return (
    <div className="bg-gray-200  rounded-lg p-4 shadow">
      <h2 className="text-xl font-semibold mb-2">{name}</h2>
      <p className="text-sm text-gray-600 mb-1">Min Contribution: {minimumContribution} ETH</p>
      <p className="text-sm text-gray-600 mb-4">Total Contributions: {totalContributions} ETH</p>
      {contract && <ContributionForm contract={contract} />}
    </div>
  );
}

export default ContractCard;