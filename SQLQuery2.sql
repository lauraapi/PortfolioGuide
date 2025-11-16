/*

Cleaning Data in SQL Queries

*/

Select *
from CleaningProect.dbo.NashvilleHousing

-- Standardize Date Format

Select SaleDate, CONVERT (Date, SaleDate)
from CleaningProect.dbo.NashvilleHousing 

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate) 

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

---------------------------------------------------------------------------------------------

-- Populate Property Address data

-- to have a first clearer clue of eventual missing data, we could:

Select *
from CleaningProect.dbo.NashvilleHousing
Where PropertyAddress is NULL

--  To populate these NULL values, we can identify double ParcelID since same ParcelID means same Property Address

Select *
from CleaningProect.dbo.NashvilleHousing
order by ParcelID

-- identified the existance of double ParcelID, we now want to populate the NULL values with the address information that is present on the second ParcelID that is not NULL, but being careful that the UniqueID is not the same (in this case would mean we have a double)

Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) 
from CleaningProect.dbo.NashvilleHousing a
JOIN CleaningProect.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <>  b.[UniqueID ]
WHERE a.PropertyAddress is NULL

-- we now obtain a new column of addresses  that correspond to the NULL values; now let's merge the empty Property Address data. (essentially merge the missing information on the basis of the double ParcelID that contains the address)

UPDATE a
SET PropertyAddress =  ISNULL(a.PropertyAddress,b.PropertyAddress) 
from CleaningProect.dbo.NashvilleHousing a
JOIN CleaningProect.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ] <>  b.[UniqueID ]
WHERE a.PropertyAddress is NULL

-- now there are no null values.

----------------------------------------------------------------------------------------------------------------------------------------------------------

-- BREAKING OUT ADDRESS INTO INDIVUDUAL COLUMNS (Address, City, State)

-- There are 2 main approaches to separate values, will be both investigated below.

Select PropertyAddress
from CleaningProect.dbo.NashvilleHousing

-- Address and city name is all together, we want to separate them
-- We can use SUBSTRING function

SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM CleaningProect.dbo.NashvilleHousing

-- Now let's update the table

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity =  SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


-- Column OwnerAddress has same issue: Address, City and State all together. 
-- We can use the PARSENAME function, considering that this function separate the values on the basis of periods, not comma.


SELECT
    PARSENAME(REPLACE(OwnerAddress, ',','.'), 3),
    PARSENAME(REPLACE(OwnerAddress, ',','.'), 2),
    PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)
FROM CleaningProect.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity =   PARSENAME(REPLACE(OwnerAddress, ',','.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCountry NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCountry = PARSENAME(REPLACE(OwnerAddress, ',','.'), 1)



--------------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in  "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM CleaningProect.dbo.NashvilleHousing
GROUP BY SoldAsVacant

-- We noticed there are several incorrect "Yes" an "No" filled as Y and N. We want to fix it.

SELECT SoldAsVacant,
CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END
FROM CleaningProect.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE
WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No'
ELSE SoldAsVacant
END


-- Running again the first query, we can see there are only Yes and No filled in.

-------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
PropertyAddress,
SalePrice,
SaleDate,
LegalReference
ORDER BY UniqueID
) row_num
FROM CleaningProect.dbo.NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1


-- All the duplicate rows are now deleted.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

-- We already split the Owner Address and Property Address columns, the original ones are much more unusable, thus, we will delete them.

SELECT *
FROM CleaningProect.dbo.NashvilleHousing

ALTER TABLE CleaningProect.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate



