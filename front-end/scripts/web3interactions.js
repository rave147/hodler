import { ethers } from "./ethers-5.1.esm.min.js"
import { abi, smartContractAddress } from "./abi.js"


let connectMetaMaskButton = document.getElementById("connectMetaMask")
connectMetaMaskButton.onclick = connectMetaMask
let hodlItButton = document.getElementById("hodlIt")
hodlItButton.onclick = startToHodl
let withdrawHodledMoneyButton = document.getElementById("withdrawHodledMoney")
withdrawHodledMoneyButton.onclick = withdrawHodledMoney


async function connectMetaMask() {
    if (typeof window.ethereum !== "undefined") {
      await ethereum.request({ method: "eth_requestAccounts" })      
      const accounts = await ethereum.request({ method: "eth_accounts" })
      connectMetaMaskButton.innerHTML = `Your account ${accounts[0]} is connected.`
    } else {
      alert("Sorry, it looks like you don't have MetaMask installed. Install the MetaMask application to use the site.")
    }
  }

  async function startToHodl() {

    let valueToHodl = document.getElementById("valueToHodl").value
    let priceToTarget = document.getElementById("priceToTarget").value

    console.log(`Funding with ${valueToHodl}...`)
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      const signer = provider.getSigner()
      const contract = new ethers.Contract(smartContractAddress, abi, signer)
      try {
        const hodlResponse = await contract.addTargetHodlValues(priceToTarget, {
          value: ethers.utils.parseEther(valueToHodl),
        })
      } catch (e) {
        alert("You already have an unfinished hodl-contract!")
      }
    } else {
      alert("It looks like you don't have MetaMask installed. Please install for further work.")
    }
  }



  async function withdrawHodledMoney() {
    if (typeof window.ethereum !== "undefined") {
      const provider = new ethers.providers.Web3Provider(window.ethereum)
      await provider.send('eth_requestAccounts', [])
      const signer = provider.getSigner()
      const contract = new ethers.Contract(smartContractAddress, abi, signer)
      try {
        const transactionResponse = await contract.hodledMoneyWithdraw()
      } catch (e) {
        alert("The time has not yet come to withdraw the hodled money. Be patient.")
      }
    } else {
      alert("It looks like you don't have MetaMask installed. Please install for further work.")
    }
  }