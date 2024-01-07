#!/bin/bash

# Script to make the following:

# Creating Virtual Networks and it's subnets
# Creating NSGs and it's Rules
# Creating Virtual Machines and passing user data to it

# You can do as many as you want from any resource just invoke the functions like below

# Use your own location, types, and names etc...
# You can modify "user-data.sh" file to your desires




clear
vmType="Standard_B1s"
location="centralus"


# Create Resource Group

create_resource_group(){

    # $1 -> group name

    RGcheck=$(az group show --resource-group $1 2>&1)
    if [ $? -ne 0 ]; then
        echo "Creating Resource Group..."
        RGinfo=$(az group create --name $1 --location $location)
        if [ $? -ne 0 ]; then
            echo "There is error when making resource group"
            exit 1
        else
            RGname=$(echo $RGinfo | grep -oP '"name": "[^"]+' | cut -d '"' -f 4)
            echo "Resource Group Provisioned: $RGname"
        fi
    else
        RGname=$(az group show --resource-group $1 --query name --output tsv)
        echo "Resource Group Already Exists"
        echo "$RGname"
    fi
}

# Create VPC
create_virtual_network(){

    # $1 -> vnet name, $2 -> subnet name, $3 -> vnet address prefix, $4 -> subnet address prefix, $5 -> resource group name

    vnetCheck=$(az network vnet show --resource-group $RGname --name $1 2>&1)
    if [ $? -ne 0 ]; then
        echo "Creating Virtual Network..."
        vnetInfo=$(az network vnet create --resource-group $RGname --name $1 --address-prefixes $3 --subnet-name $2 --subnet-prefixes $4 --location $location)
        if [ $? -ne 0 ]; then
            echo "There is an error making virtual network"
            exit 1
        else
            vnetName=$(az network vnet show --resource-group $5 --name $1 --query "name" --output tsv)
            echo "Virutal Network Provisioned: $vnetName"
        fi
    else
        vnetName=$(az network vnet show --resource-group $5 --name $1 --query "name" --output tsv)
        echo "Virtual Network Already exists."
        echo $vnetName
    fi
}


# Create Subnet

create_subnets(){
    # $1 -> subnet name, $2 -> vnet name, $3 -> address prefix, $4 -> resource group
    subnet_check=$(az network vnet subnet show --resource-group $4 --vnet-name $2 --name $1 2>&1)
    if [ $? -ne 0 ]; then
        echo "Creating subnet..."
        subnetInfo=$(az network vnet subnet create --resource-group $4 --vnet-name $2 --name $1 --address-prefixes $3)
        if [ $? -ne 0 ]; then
            echo "There is an error making subnet"
            exit 1
        else
            subnetName=$(az network vnet subnet show --resource-group $4 --vnet-name $2 --name $1 --query "name" --output tsv)
            echo "Subnet Provisioned: $subnetName"
        fi
    else
        subnetName=$(az network vnet subnet show --resource-group $4 --vnet-name $2 --name $1 --query "name" --output tsv)
        echo "$subnetName Already exists"
    fi
}



# Create NSG
create_nsg(){
    # $1 -> nsg name, $2 -> resource group
    nsgCheck=$(az network nsg show --resource-group $2 --name $1 2>&1)
    if [ $? -ne 0 ]; then
        echo "Creating Network Security Group..."
        nsgInfo=$(az network nsg create --resource-group $2 --name $1 --location $location)
        if [ $? -ne 0 ]; then
            echo "There is an error making nsg"
            exit 1
        else
            nsgName=$(az network nsg show --resource-group $2 --name $1 --query "name" --output tsv)
            echo "Network Security Group Provisioned: $nsgName"
        fi
    else
        nsgName=$(az network nsg show --resource-group $2 --name $1 --query "name" --output tsv)
        echo "NSG already exists"
        echo "$nsgName"
    fi
}


# Create NSG Rule

create_nsg_rule(){
    # $1 -> nsg name, $2 -> resource group, $3 -> rule name, $4 -> priority, $5 -> action, $6 -> source prefix, $7 -> destination prefix, $8 -> source port ranges, $9 -> destination port ranges, $10 -> protocols, $11 -> direction
    nsgRuleCheck=$(az network nsg rule show --resource-group $2 --nsg-name $1 --name $3 2>&1)
    if [ $? -ne 0 ]; then
        echo "Creating NSG Rule..."
        nsgRuleInfo=$(az network nsg rule create --resource-group $2 --name $3 --nsg-name $1 --priority $4 --access $5 --source-address-prefixes $6 --destination-address-prefixes $7 --source-port-ranges $8 --destination-port-ranges $9 --protocol ${10} --direction ${11})
        if [ $? -ne 0 ]; then
            echo "There is an error making nsg rule"
            exit 1
        else
            nsgRuleName=$(az network nsg rule show --resource-group $2 --nsg-name $1 --name $3 --query "name" --output tsv)
            echo "NSG Rule Provisioned: $nsgRuleName"
        fi
    else
        nsgRuleName=$(az network nsg rule show --resource-group $2 --nsg-name $1 --name $3 --query "name" --output tsv)
        echo "NSG Rule Already Exists."
        echo $nsgRuleName
    fi
}

# Associate Subnet With NSG

associate_subnet_with_nsg(){
    # $1 -> resource group name, $2 -> vnet name, $3 -> subnet name, $4 -> nsg name
    checkSubnetRule=$(az network vnet subnet show --resource-group $1 --vnet-name $2 --name $3 --query "networkSecurityGroup.id" --output tsv)
    if [ "$checkSubnetRule" == "" ]; then
        echo "Associating NSG Rule With $3"
        associateRule=$(az network vnet subnet update --resource-group $1 --vnet-name $2 --name $3 --network-security-group $4)
        if [ $? -ne 0 ]; then
            echo "There is an error associating nsg rule to $3"
            exit 1
        else
            echo "Done associating $4 NSG to $3"
        fi
    else
        echo "$3 already associated with $4."
    fi
}

# Create VM
create_vm(){
    # $1 -> resource group, $2 -> vm name, $3 -> image, $4 -> vnet name, $5 -> subnet name, $6 -> nsg name, $7 key pair located, $8 -> admin username, $9-> user data
    checkVm=$(az vm show --resource-group $1 --name $2 2>&1)
    if [ $? -ne 0 ]; then
        echo "Creating Virtual Machine..."
        vmInfo=$(az vm create --resource-group $1 --name $2 --image $3 --vnet-name $4 --subnet $5 --nsg $6 --ssh-key-value $7 --admin-username $8 --size $vmType --user-data $9)
        if [ $? -ne 0 ]; then
            echo "There is an error making $2 vm."
            exit 1
        else
            vmName=$(az vm show --resource-group $1 --name $2 --query "name" --output tsv)
            echo "Vm Provisioned."
            vmPublicIp=$(az vm show --resource-group $1 --name $2 --show-details --query "publicIps" --output tsv)
            echo "$vmName Public Ip: $vmPublicIp"
        fi
    else
        echo "$2 Already Exists."
    fi
}


# --------------------------------------------------------------------------------------------------


# Invoking functions to create resources

create_resource_group "test-group" "centralus"
echo
echo "-----------------------------------------------------------------------------------"
echo
create_virtual_network "test-vnet" "public-subnet" "10.0.0.0/16" "10.0.1.0/24" "$RGname"
echo
echo "-----------------------------------------------------------------------------------"
echo
create_subnets "private-subnet" "$vnetName" "10.0.2.0/24" "$RGname"
echo
echo "-----------------------------------------------------------------------------------"
echo
create_nsg "test-nsg" "$RGname"
echo
echo "-----------------------------------------------------------------------------------"
echo
create_nsg_rule "$nsgName" "$RGname" "allow-ssh" "100" "allow" "197.48.152.144/32" "0.0.0.0/0" "0-65535" 22 "Tcp" "Inbound"
echo
echo "-----------------------------------------------------------------------------------"
echo
create_nsg_rule "$nsgName" "$RGname" "allow-http" "101" "allow" "197.48.152.144/32" "0.0.0.0/0" "0-65535" 80 "Tcp" "Inbound"
echo
echo "-----------------------------------------------------------------------------------"
echo
associate_subnet_with_nsg "$RGname" "$vnetName" "public-subnet" "$nsgName"
echo
echo "-----------------------------------------------------------------------------------"
echo
create_vm "$RGname" "public-vm" "Ubuntu2204" "$vnetName" "public-subnet" "$nsgName" "~/key/azure-key.pub" "ubuntu" @./user-data.sh
echo
echo "Recommendation: Allow 1 or 2 minutes to elapse before attempting any actions to ensure that everything has settled."
echo
echo "End Script"
