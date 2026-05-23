'use client';

import { createContext, useContext, ReactNode } from 'react';
import { TenantConfig, DEFAULT_TENANT, TENANTS } from '@/config/tenants';

const TenantContext = createContext<TenantConfig>(TENANTS[DEFAULT_TENANT]);

/**
 * Provides the tenant configuration to all descendent components.
 * Wrap at the root layout level so useTenant() works everywhere.
 */
export function TenantProvider({
  tenant,
  children,
}: {
  tenant: string;
  children: ReactNode;
}) {
  const config = TENANTS[tenant] || TENANTS[DEFAULT_TENANT];
  return (
    <TenantContext.Provider value={config}>{children}</TenantContext.Provider>
  );
}

/**
 * Access the current tenant configuration from any client component.
 */
export function useTenant(): TenantConfig {
  return useContext(TenantContext);
}
